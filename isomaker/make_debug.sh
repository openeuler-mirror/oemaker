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
function down_ava_debug_rpm()
{
    [ -d "$DBG_DIR" ] && rm -rf "$DBG_DIR"
    yum list --installroot="${BUILD}"/tmp available | awk '{print $1}' | grep -E 'devel|debuginfo' | grep -v "i686" > ava_deb_lst
    local yumdownloader_log_startline=$(($(awk 'END{print NR}' /var/log/dnf.log)+1))
    yumdownloader --installroot="${BUILD}"/tmp --destdir="$DBG_DIR" $(cat ava_deb_lst | tr '\n' ' ') > /dev/null
    if [ $? -ne 0 ] || sed -n ''${yumdownloader_log_startline}',$p' /var/log/dnf.log | grep -n 'conflicting requests'; then
        return 1
    fi
    return 0
}

function get_debug_rpm()
{
    rm -rf debug_rpm_lst
    set +e
    rpm -qpi "$BUILD"/iso/Packages/*.rpm | grep "Source RPM" | awk '{print $4}' | sort | uniq > iso_src_lst
    for debug_rpm in $(ls "$DBG_DIR" | grep rpm$)
    do
        src_name=$(rpm -qpi "$DBG_DIR"/"$debug_rpm" | grep "Source RPM" | awk '{print $4}')
        grep "^$src_name$" iso_src_lst > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            [ -n "$debug_rpm" ] && rm -rf "$DBG_DIR"/"$debug_rpm"
        else
            rpm -qp --qf "%{NAME}.%{ARCH}\n" "$DBG_DIR"/"$debug_rpm" >> debug_rpm_lst
        fi
    done
    set -e
    local yumdownloader_log_startline=$(($(awk 'END{print NR}' /var/log/dnf.log)+1))
    yumdownloader --resolve --installroot="${BUILD}"/tmp --destdir="$DBG_DIR" $(cat debug_rpm_lst | tr '\n' ' ')
    if [ $? -ne 0 ] || sed -n ''${yumdownloader_log_startline}',$p' /var/log/dnf.log | grep -n 'conflicting requests'; then
        echo "Download debug rpms failed!"
        return 1
    fi
    ls "${BUILD}"/iso/Packages/ | sort > iso_lst
    ls "$DBG_DIR"/ |sort > deb_lst
    for del_rpm in $(cat iso_lst deb_lst | sort -n | uniq -d)
    do
        [ -n "$del_rpm" ] && rm -rf "$DBG_DIR"/"$del_rpm"
    done
    return 0
}
