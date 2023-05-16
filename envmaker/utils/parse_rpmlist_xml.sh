:<<!
 * Copyright (c) Huawei Technologies Co., Ltd. 2018-2023. All rights reserved.
 * oemaker licensed under the Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *     http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
 * PURPOSE.
 * See the Mulan PSL v2 for more details.
 * Author:
 * Create: 2023-05-05
 * Description: provide xml parse function
!

#!/bin/bash
set -e

function parse_rpmlist_xml() {
    local rpmlist_xml=$1
    local package_type=$2
    rpmlist_xml_path=$(dirname "${rpmlist_xml}")
    rpmlist_xml_name=$(basename "${rpmlist_xml}" .xml)
    xmllint --xpath "//packagelist[@type='${package_type}']/node()" "${rpmlist_xml}" > "${rpmlist_xml_path}/origin_${rpmlist_xml_name}_${package_type}"
    cat "${rpmlist_xml_path}/origin_${rpmlist_xml_name}_${package_type}" | grep packagereq |cut -d ">" -f 2 | cut -d "<" -f 1 > "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}_${package_type}"
    return 0
}

function extract_rpmlist_from_xml() {
    local rpmlist_xml=$1
    local package_type=$2
    local rpmlist_xml_path=$(dirname "${rpmlist_xml}")
    local rpmlist_xml_name=$(basename "${rpmlist_xml}" .xml)
    parse_rpmlist_xml "${rpmlist_xml}" "${package_type}"
    cat "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}_${package_type}" > "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}"
    parse_rpmlist_xml "${rpmlist_xml}" "common"
    cat "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}_common" >> "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}"
    sort -r -u "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}" -o "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}"
    parse_rpmlist_xml "${rpmlist_xml}" "exclude"
    cat "${rpmlist_xml_path}/parsed_${rpmlist_xml_name}_exclude" > "${rpmlist_xml_path}/exclude_rpms"
    sort -r -u "${rpmlist_xml_path}/exclude_rpms" -o "${rpmlist_xml_path}/exclude_rpms"
    return 0
}
