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

function download_rpms()
{
    if [ "${ISO_TYPE}" == "edge" ]; then
        get_edge_rpms
        return 0
    elif [ "${ISO_TYPE}" == "desktop" ]; then
        get_desktop_rpms
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
    yum list --installroot="${BUILD}"/tmp available | awk '{print $1}' > __list.arch

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
            rname_tmp=`repoquery --queryformat="%{name}.%{arch}" -q --whatprovides $rname`
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
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat __rpm.list | tr '\n' ' ') ${exclude_cmd}
    if [ $? != 0 ] || sed -n ''${yumdownloader_log_startline}',$p' /var/log/dnf.log | grep -n 'conflicting requests'; then
       echo "Download rpms failed!"
       exit 133
    fi

    parse_rpmlist_xml "conflict"
    set -e
    if [ -s parsed_rpmlist_conflict ];then
        yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat parsed_rpmlist_conflict | tr '\n' ' ') ${exclude_cmd}
    fi

    set +e
    if [ "${ISO_TYPE}" == "debug" ]; then
        down_ava_debug_rpm
        get_debug_rpm
    elif [ "${ISO_TYPE}" == "source" ]; then
        [ -d "$SRC_DIR" ] && rm -rf "$SRC_DIR"
        mkdir "$SRC_DIR"
        ls "${BUILD}"/iso/Packages/ | sed 's/.rpm$//g'| tr '\n' ' ' | sort | uniq | xargs yumdownloader --installroot="${BUILD}"/tmp --source --destdir="$SRC_DIR"
        yumdownloader kernel-source  --installroot="${BUILD}"/tmp  --destdir="$SRC_DIR"
    elif [ "${ISO_TYPE}" == "everything" ]; then
        everything_rpms_download
    elif [ "${ISO_TYPE}" == "everything_src" ]; then
        everything_source_rpms_download
    elif [ "${ISO_TYPE}" == "everything_debug" ]; then
        everything_debug_rpms_download
    fi

    mkdir -p "${BUILD}"/iso/repodata
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    createrepo -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
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
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _edge_rpms.lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls "${BUILD}"/iso/Packages/ | wc -l) == 0 ]; then
        echo "Download rpms failed!"
        exit 133
    fi
}

function get_desktop_rpms()
{
    parse_rpmlist_xml "desktop_${ARCH}"
    cat parsed_rpmlist_desktop_${ARCH} > _desktop_rpms.lst
    parse_rpmlist_xml "desktop_common"
    cat parsed_rpmlist_desktop_common >> _desktop_rpms.lst
    cat "config/${ARCH}/desktop_normal.xml" | grep packagereq | cut -d ">" -f 2 | cut -d "<" -f 1 >> _desktop_rpms.lst
    sort -r -u _desktop_rpms.lst -o _desktop_rpms.lst
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${BUILD}"/iso/Packages/ $(cat _desktop_rpms.lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls "${BUILD}"/iso/Packages/ | wc -l) == 0 ]; then
        echo "Download rpms failed!"
        exit 133
    fi
}

function get_everything_rpms()
{
    yum list --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep -E "\.noarch|\.${ARCH}" | grep -v "debuginfo" | grep -v "debugsource" > ava_every_lst
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
            sed -i "/^${rpmname}\./d" ava_every_lst
            echo "${rpmname}" >> conflict_list
        done
    fi 
    parse_rpmlist_xml "everything_conflict"
    cat parsed_rpmlist_everything_conflict
    if [ -s parsed_rpmlist_everything_conflict ];then
        for rpmname in $(cat parsed_rpmlist_everything_conflict)
        do
            sed -i "/^${rpmname}\./d" ava_every_lst
            echo "${rpmname}" >> conflict_list
        done
    fi 
}

function everything_rpms_download()
{
    mkdir ${EVERY_DIR}
    get_everything_rpms
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${EVERY_DIR}" $(cat ava_every_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_DIR} | wc -l) == 0 ]; then
       echo "Download rpms failed!"
       exit 133
    fi
    if [ -s conflict_list ];then
        yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${EVERY_DIR}" $(cat conflict_list | tr '\n' ' ')
    fi
}

function everything_source_rpms_download()
{
    mkdir ${EVERY_SRC_DIR}
    yum list --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep ".src" > ava_every_lst
    parse_rpmlist_xml "src_exclude"
    cat parsed_rpmlist_src_exclude
    if [ -s parsed_rpmlist_src_exclude ];then
        for rpmname in $(cat parsed_rpmlist_src_exclude)
        do
            sed -i "/^${rpmname}\./d" ava_every_lst
        done
    fi 
    yumdownloader --installroot="${BUILD}"/tmp --destdir="${EVERY_SRC_DIR}" --source $(cat ava_every_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_SRC_DIR} | wc -l) == 0 ]; then
       echo "Download rpms failed!"
       exit 133
    fi
}
 
function everything_debug_rpms_download()
{
    mkdir ${EVERY_DEBUG_DIR}
    yum list --installroot="${BUILD}"/tmp --available | awk '{print $1}' | grep -E "debuginfo|debugsource" > ava_debug_lst
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="${EVERY_DEBUG_DIR}" $(cat ava_debug_lst | tr '\n' ' ')
    if [ $? != 0 ] || [ $(ls ${EVERY_DEBUG_DIR} | wc -l) == 0 ]; then
        echo "yumdownloader with --resolve failed, trying to yumdownloader without --resolve"
        yumdownloader --installroot="${BUILD}"/tmp --destdir="${EVERY_DEBUG_DIR}" $(cat ava_debug_lst | tr '\n' ' ')
    fi
}
 
