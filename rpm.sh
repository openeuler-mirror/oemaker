:<<!
 * Copyright (c) Huawei Technologies Co., Ltd. 2018-2019. All rights reserved.
 * iSulad licensed under the Mulan PSL v2.
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
        if [ $(echo "$rname" | grep "\*$") ]; then
            echo "$rname" >> __rpm.list
            continue
        fi
        rname=$(echo "$rname")
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
            rname=`repoquery --queryformat="%{name}.%{arch}" -q --whatprovides $rname`
            if [ -z "$rname" ]; then
                echo "cannot find $rname in yum repo" >> not_find
                ret=1
                continue
            else
                echo "$rname" >> __rpm.list
                continue
            fi
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
        for rpmname in `cat parsed_rpmlist_exclude`;do
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
    if [ "${ISOTYPE}" == "debug" ]; then
        down_ava_debug_rpm
        get_debug_rpm
    elif [ "${ISOTYPE}" == "source" ]; then
        [ -d "$SRC_DIR" ] && rm -rf "$SRC_DIR"
        mkdir "$SRC_DIR"
        ls "${BUILD}"/iso/Packages/ | sed 's/.rpm$//g'| tr '\n' ' ' | sort | uniq | xargs yumdownloader --installroot="${BUILD}"/tmp --source --destdir="$SRC_DIR"
        yumdownloader kernel-source  --installroot="${BUILD}"/tmp  --destdir="$SRC_DIR"
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
