:<<!
 * Copyright (c) Huawei Technologies Co., Ltd. 2018-2019. All rights reserved.
 * oemaker licensed under the Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *     http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
 * PURPOSE.
 * See the Mulan PSL v2 for more details.
 * Author: zhuchunyi
 * Create: 2020-08-05
 * Description: provide container buffer functions
!

#!/bin/bash

set -e
function parse_rpmlist_xml()
{
    packagetype=$1
    xmllint --xpath "//packagelist[@type='${packagetype}']/node()" "${CONFIG_RPM_LIST}" > origin_rpmlist_${packagetype}
    cat origin_rpmlist_${packagetype} | grep packagereq | cut -d ">" -f 2 | cut -d "<" -f 1 > parsed_rpmlist_${packagetype}
    return 0
}

# 富依赖闭包检查与自动补下载：
# 富依赖如 (A if B) 在依赖求解时条件 B 不成立则不会下载 A，但安装阶段一旦启用 B 就会因缺 A 失败。
# 本函数在打 ISO 前主动检查：只要条件 B 已可被 ISO 中的包满足（包名或虚拟 Provides，如
# selinux-policy-base 由 selinux-policy 提供），结果包 A 就必须也存在；
# 缺失时自动通过 yumdownloader 补下载（--resolve 会同时拉取其自身依赖），并循环迭代直至闭包收敛。
function check_and_fix_rich_deps()
{
    local max_iter=10
    local iter=0
    local added=0
    local dep subject condition op rpmname found
    local exclude_cmd=""
    if [ -s parsed_rpmlist_exclude ]; then
        for rpmname in $(cat parsed_rpmlist_exclude); do
            exclude_cmd="${exclude_cmd} -x ${rpmname}"
        done
    fi

    while [ "${iter}" -lt "${max_iter}" ]; do
        iter=$((iter + 1))
        added=0
        # 1. 先提取所有富依赖表达式 (A if B) / (A unless B)
        rpm -qp --requires "${BUILD}"/iso/Packages/*.rpm 2>/dev/null \
            | grep -v '^[^:]*:$' \
            | grep -E '^\(.* (if|unless) .*\)$' > _rich_deps.lst || true
        # 无富依赖时直接收敛：跳过全量能力收集，避免无谓的 rpm 遍历开销（4000 包时省 2/3）
        if [ ! -s _rich_deps.lst ]; then
            break
        fi
        # 2. 收集 ISO 内已有包可提供的全部"能力"（包名 + 虚拟 Provides，如 selinux-policy-base
        #    由 selinux-policy 提供），用于判断富依赖的条件/结果是否可被满足
        rpm -qp --queryformat '%{NAME}\n' "${BUILD}"/iso/Packages/*.rpm 2>/dev/null | sort -u > _packages.names
        rpm -qp --provides "${BUILD}"/iso/Packages/*.rpm 2>/dev/null \
            | grep -v '^[^:]*:$' \
            | sed -E 's/ [<>=]+ .*$//' \
            | sort -u > _packages.provides
        sort -u _packages.names _packages.provides -o _packages.all

        : > _rich_missing.lst
        while read -r dep; do
            [ -z "${dep}" ] && continue
            case "${dep}" in
                *' if '*) op="if" ;;
                *' unless '*) op="unless" ;;
                *) continue ;;
            esac
            subject=$(echo "${dep}" | sed -E 's/^\((.*) (if|unless) .*\)$/\1/' | awk '{print $1}')
            condition=$(echo "${dep}" | sed -E 's/^\((.*) (if|unless) (.*)\)$/\3/' | awk '{print $1}')
            if [ -z "${subject}" ] || [ -z "${condition}" ]; then
                continue
            fi
            # 排除清单中的包不强制补
            if [ -s parsed_rpmlist_exclude ]; then
                grep -qx "${subject}" parsed_rpmlist_exclude && continue
            fi
            # 结果包已可由 ISO 内包满足（包名或虚拟 Provides）则无需处理
            grep -qx "${subject}" _packages.all && continue
            if [ "${op}" == "if" ]; then
                # (A if B)：条件 B 可被 ISO 内包满足（如 selinux-policy 提供 selinux-policy-base）时要求 A 存在
                grep -qx "${condition}" _packages.all || continue
            else
                # (A unless B)：条件 B 不可被 ISO 内包满足时才要求 A 存在
                grep -qx "${condition}" _packages.all && continue
            fi
            echo "${subject}" >> _rich_missing.lst
        done < _rich_deps.lst

        if [ ! -s _rich_missing.lst ]; then
            break
        fi
        # 3. 将缺失包解析为仓库中真实存在的包名：
        #    a) 先按"能力"查（--whatprovides，兼容虚拟依赖）
        #    b) 查不到时按"包名"查（部分 dnf 版本 --whatprovides 不匹配包自身的名称提供）
        #    c) 仍查不到且是合法包名格式时，交给 yumdownloader 用裸名解析（存在即下载，不存在即报错，提前暴露问题）
        : > _rich_fix.lst
        while read -r pkg; do
            found=$(repoquery --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --queryformat="%{name}.%{arch}" -q --whatprovides "${pkg}" 2>/dev/null || true)
            if [ -z "${found}" ]; then
                found=$(repoquery --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --queryformat="%{name}.%{arch}" -q "${pkg}" 2>/dev/null || true)
            fi
            if [ -n "${found}" ]; then
                echo "${found}" >> _rich_fix.lst
            elif echo "${pkg}" | grep -qE '^[a-zA-Z0-9._+-]+$'; then
                echo "${pkg}" >> _rich_fix.lst
            else
                echo "[WARN] rich dependency target '${pkg}' is not a valid package name, skip it" >&2
            fi
        done < <(sort -u _rich_missing.lst)

        if [ ! -s _rich_fix.lst ]; then
            echo "[WARN] missing rich dependency packages unresolvable, please check rpmlist.xml" >&2
            break
        fi
        # 4. 自动补下载（--resolve 会同时拉取其自身依赖），随后进入下一轮迭代检查
        added=1
        echo "Auto download missing rich-dependency packages: $(tr '\n' ' ' < _rich_fix.lst)"
        yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _rich_fix.lst | tr '\n' ' ') ${exclude_cmd} || {
            echo "Auto download rich-dependency packages failed!"
            exit 133
        }
    done

    if [ "${iter}" -ge "${max_iter}" ] && [ "${added}" -ne 0 ]; then
        echo "[WARN] rich dependency closure not converged after ${max_iter} rounds" >&2
    fi
    rm -f _packages.names _packages.provides _packages.all _rich_deps.lst _rich_missing.lst _rich_fix.lst
    return 0
}

function download_rpms()
{
    if [ "${ISO_TYPE}" == "edge" ]; then
        get_edge_rpms
        return 0
    elif [ "${ISO_TYPE}" == "desktop" ]; then
        get_desktop_rpms
        return 0
    elif [ "${ISO_TYPE}" == "devstation" ] || [ "${ISO_TYPE}" == "devstation_netinst" ]; then
        get_devstation_rpms
        return 0
    fi

    cat "${CONFIG}" | grep packagereq | cut -d ">" -f 2 | cut -d "<" -f 1 > _all_rpms.lst
    parse_rpmlist_xml "${ARCH}"
    cat parsed_rpmlist_${ARCH} >> _all_rpms.lst
    parse_rpmlist_xml "common"
    cat parsed_rpmlist_common >> _all_rpms.lst
    sort -r -u _all_rpms.lst -o _all_rpms.lst

    [ -d "${BUILD}"/tmp ] && rm -rf "${BUILD}"/tmp
    ret=0
    rm -rf not_find __*
    yum list --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp available | awk '{print $1}' > __list.arch

    set +e
    for rname in $(cat _all_rpms.lst)
    do
        if [ -z "${rname}" ];then
            continue
        fi
        if [ $(echo "$rname" | grep "\*$") ]; then
            echo "$rname" >> __rpm.list
            continue
        fi
        rarch=${rname##*.}
        if [ "X$rarch" == "Xi686" ] && [ "$ARCH" == "aarch64" ]; then
            continue
        fi
        if [ "X$rarch" == "Xx86_64" ] && [ "$ARCH" == "aarch64" ]; then
            rname=${rname%%.*}
            rarch="aarch64"
        fi
        cat __list.arch | grep -w "^$rname" > /dev/null 2>&1
        if [ $? != 0 ]; then
            rname_tmp=`repoquery --setopt=reposdir=yum.repos.d --queryformat="%{name}.%{arch}" -q --whatprovides $rname`
            if [ -z "${rname_tmp}" ]; then
                echo "cannot find $rname in yum repo" >> not_find
                ret=1
                continue
            else
                echo "$rname" >> __rpm.list
                continue
            fi
            rname=${rname_tmp}
        fi
        if [ "X$rarch" == "Xi686" ] || [ "X$rarch" == "Xx86_64" ] || [ "X$rarch" == "Xnoarch" ] || [ "X$rarch" == "Xaarch64" ]; then
            rname="${rname}"
        else
            cat __list.arch | grep -w "^$rname.$ARCH" > /dev/null 2>&1
            if [ $? == 0 ]; then
                rname="${rname}"."${ARCH}"
            else
                cat __list.arch | grep -w "^$rname.noarch" > /dev/null 2>&1
                if [ $? == 0 ]; then
                    rname="${rname}".noarch
                else
                    echo "cannot find $rname in yum repo" >> not_find
                    ret=1
                fi
            fi
        fi
        echo "$rname" >> __rpm.list
    done
    if [ "${ret}" -ne 0 ]; then
        cat not_find|sort|uniq
        exit "${ret}"
    fi

    parse_rpmlist_xml "exclude"
    local exclude_cmd=""
    if [ -s parsed_rpmlist_exclude ];then
        for rpmname in $(cat parsed_rpmlist_exclude);do
            exclude_cmd="${exclude_cmd} -x ${rpmname}"
        done
    fi
    local yumdownloader_log_startline=$(($(awk 'END{print NR}' /var/log/dnf.log)+1))
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat __rpm.list | tr '\n' ' ') ${exclude_cmd}
    if [ $? != 0 ] || sed -n ''${yumdownloader_log_startline}',$p' /var/log/dnf.log | grep -n 'conflicting requests'; then
       echo "Download rpms failed!"
       exit 133
    fi

    parse_rpmlist_xml "conflict"
    set -e
    if [ -s parsed_rpmlist_conflict ];then
        yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat parsed_rpmlist_conflict | tr '\n' ' ') ${exclude_cmd}
    fi

    set +e
    if [ "${ISO_TYPE}" == "debug" ]; then
        down_ava_debug_rpm
        get_debug_rpm
    elif [ "${ISO_TYPE}" == "source" ]; then
        [ -d "$SRC_DIR" ] && rm -rf "$SRC_DIR"
        mkdir "$SRC_DIR"
        ls "${BUILD}"/iso/Packages/ | sed 's/.rpm$//g'| tr '\n' ' ' | sort | uniq | xargs yumdownloader --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --source --destdir="$SRC_DIR"
        yumdownloader kernel-source --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp  --destdir="$SRC_DIR"
    elif [ "${ISO_TYPE}" == "everything" ]; then
        everything_rpms_download
    elif [ "${ISO_TYPE}" == "everything_src" ]; then
        everything_source_rpms_download
    elif [ "${ISO_TYPE}" == "everything_debug" ]; then
        everything_debug_rpms_download
    fi

    # 富依赖闭包检查与自动补下载：提前暴露并补齐安装阶段才会缺失的条件依赖
    check_and_fix_rich_deps

    mkdir -p "${BUILD}"/iso/repodata
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    return 0
}

function get_rpm_pub_key()
{
    mkdir -p "${BUILD}"/iso/GPG_tmp
    cp "${BUILD}"/iso/Packages/openEuler-gpg-keys* "${BUILD}"/iso/GPG_tmp
    cd "${BUILD}"/iso/GPG_tmp
    rpm2cpio openEuler-gpg-keys* | cpio -div ./etc/pki/rpm-gpg/RPM-GPG-KEY-openEuler
    cd -
    cp "${BUILD}"/iso/GPG_tmp/etc/pki/rpm-gpg/RPM-GPG-KEY-openEuler "${BUILD}"/iso
    rm -rf "${BUILD}"/iso/GPG_tmp
}

function get_edge_rpms()
{
    parse_rpmlist_xml "edge_${ARCH}"
    cat parsed_rpmlist_edge_${ARCH} > _edge_rpms.lst
    parse_rpmlist_xml "edge_common"
    cat parsed_rpmlist_edge_common >> _edge_rpms.lst
    cat "config/${ARCH}/edge_normal.xml" | grep packagereq | cut -d ">" -f 2 | cut -d "<" -f 1 >> _edge_rpms.lst
    sort -r -u _edge_rpms.lst -o _edge_rpms.lst
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _edge_rpms.lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls "${BUILD}"/iso/Packages/ | wc -l) == 0 ]; then
        echo "Download rpms failed!"
        exit 133
    fi
    check_and_fix_rich_deps
}

function get_desktop_rpms()
{
    parse_rpmlist_xml "desktop_${ARCH}"
    cat parsed_rpmlist_desktop_${ARCH} > _desktop_rpms.lst
    parse_rpmlist_xml "desktop_common"
    cat parsed_rpmlist_desktop_common >> _desktop_rpms.lst
    cat "config/${ARCH}/desktop_normal.xml" | grep packagereq | cut -d ">" -f 2 | cut -d "<" -f 1 >> _desktop_rpms.lst
    sort -r -u _desktop_rpms.lst -o _desktop_rpms.lst
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _desktop_rpms.lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls "${BUILD}"/iso/Packages/ | wc -l) == 0 ]; then
        echo "Download rpms failed!"
        exit 133
    fi
    check_and_fix_rich_deps
}

function get_devstation_rpms()
{
    cat "config/${ARCH}/livecd/devstation_rpmlist" >> _devstation_rpms.lst
    sort -r -u _devstation_rpms.lst -o _devstation_rpms.lst
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _devstation_rpms.lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls "${BUILD}"/iso/Packages/ | wc -l) == 0 ]; then
        echo "Download rpms failed!"
        exit 133
    fi
    check_and_fix_rich_deps
}

function get_everything_rpms()
{
    yum list --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep -E "\.noarch|\.${ARCH}" | grep -v "debuginfo" | grep -v "debugsource" > ava_every_lst
    parse_rpmlist_xml "exclude"
    cat parsed_rpmlist_exclude
    if [ -s parsed_rpmlist_exclude ];then
        for rpmname in $(cat parsed_rpmlist_exclude)
        do
            sed -i "/^${rpmname}\./d" ava_every_lst
        done
    fi 
    if [ -s conflict_list ];then
        rm -rf conflict_list
    fi
    parse_rpmlist_xml "conflict"
    cat parsed_rpmlist_conflict
    if [ -s parsed_rpmlist_conflict ];then
        for rpmname in $(cat parsed_rpmlist_conflict)
        do
	    cat ava_every_lst | grep "^${rpmname}\."
	    if [ $? -eq 0 ];then
		sed -i "/^${rpmname}\./d" ava_every_lst
		echo "${rpmname}" >> conflict_list
	    fi
        done
    fi 
    parse_rpmlist_xml "everything_conflict"
    cat parsed_rpmlist_everything_conflict
    if [ -s parsed_rpmlist_everything_conflict ];then
        for rpmname in $(cat parsed_rpmlist_everything_conflict)
        do
	    cat ava_every_lst | grep "^${rpmname}\."
	    if [ $? -eq 0 ];then
		sed -i "/^${rpmname}\./d" ava_every_lst
		echo "${rpmname}" >> conflict_list
	    fi
        done
    fi 
}

function everything_rpms_download()
{
    mkdir ${EVERY_DIR}
    get_everything_rpms
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${EVERY_DIR}" $(cat ava_every_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_DIR} | wc -l) == 0 ]; then
       echo "Download rpms failed!"
       exit 133
    fi
    if [ -s conflict_list ];then
        yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${EVERY_DIR}" $(cat conflict_list | tr '\n' ' ')
    fi
}

function everything_source_rpms_download()
{
    mkdir ${EVERY_SRC_DIR}
    yum list --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep "\.src" > ava_every_lst
    parse_rpmlist_xml "src_exclude"
    cat parsed_rpmlist_src_exclude
    if [ -s parsed_rpmlist_src_exclude ];then
        for rpmname in $(cat parsed_rpmlist_src_exclude)
        do
            sed -i "/^${rpmname}\./d" ava_every_lst
        done
    fi 
    yumdownloader --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${EVERY_SRC_DIR}" --source $(cat ava_every_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_SRC_DIR} | wc -l) == 0 ]; then
       echo "Download rpms failed!"
       exit 133
    fi
}
 
function everything_debug_rpms_download()
{
    mkdir ${EVERY_DEBUG_DIR}
    yum list --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep -E "debuginfo|debugsource" > ava_debug_lst
    parse_rpmlist_xml "everything_debug_exclude"
    cat parsed_rpmlist_everything_debug_exclude
    if [ -s parsed_rpmlist_everything_debug_exclude ];then
        for rpmname in $(cat parsed_rpmlist_everything_debug_exclude)
        do
            sed -i "/^${rpmname}\./d" ava_debug_lst
        done
    fi
    yumdownloader --resolve --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${EVERY_DEBUG_DIR}" $(cat ava_debug_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_DEBUG_DIR} | wc -l) == 0 ]; then
        echo "yumdownloader with --resolve failed, trying to yumdownloader without --resolve"
        yumdownloader --setopt=reposdir=yum.repos.d --installroot="${BUILD}"/tmp --destdir="${EVERY_DEBUG_DIR}" $(cat ava_debug_lst | tr '\n' ' ')
    fi
}
 
