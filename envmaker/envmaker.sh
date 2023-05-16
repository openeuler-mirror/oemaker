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
 * Description: provide compile_env make functions
!

#!/bin/bash
set -e

umask 0022

BUILD_ROOT=$(pwd)
ARCH=$(uname -i)

RPMLIST_CON="compile_env_rpmlist.xml"
COMPILE_ENV_ROOT="openEuler_compile_env"
CONFIG_ROOT="config_file"
WORKSPACE="${BUILD_ROOT}/workspace"
YUM_CONF="${WORKSPACE}/${CONFIG_ROOT}/openEuler_repo.conf"
VERSION="1.0.0"
PRODUCT_NAME="openEuler_compile_env_${ARCH}"

source ${BUILD_ROOT}/utils/parse_rpmlist_xml.sh
source ${BUILD_ROOT}/utils/common_fun.sh

function parse_params() {
    while getopts ":p:v:h" opt
    do
        case "$opt" in
            p)
                PRODUCT_NAME="${OPTARG}"
            ;;
            v)
                VERSION="${OPTARG}"
            ;;
            h)
                envmaker_usage
                exit 0
            ;;
            ?)
                echo "error: please check the params."
                envmaker_usage
                return 1
            ;;
        esac
    done
}

function envmaker_usage() {
    cat << EOF
Usage: envmaker [-h] [-p Product] [-v Version]

optional arguments:
    -p Product     Product name, such as: openEuler_compile_env
    -v Version     Version identifier
    -h Help        Show the help message and exit
EOF
}

function make_clean() {
    if [[ -d ${WORKSPACE} ]];then
        rm -rf ${WORKSPACE}
    fi
}

function parse_rpmlist() {
    mkdir -p ${WORKSPACE}/${CONFIG_ROOT}
    cp ${BUILD_ROOT}/config/${RPMLIST_CON} ${WORKSPACE}/${CONFIG_ROOT}
    cp ${BUILD_ROOT}/config/${ARCH}/* ${WORKSPACE}/${CONFIG_ROOT}
    local rpmlist_xml="${WORKSPACE}/${CONFIG_ROOT}/${RPMLIST_CON}"
    extract_rpmlist_from_xml "${rpmlist_xml}" "${ARCH}"
}

function install_rpm() {
    mkdir -p ${WORKSPACE}/${COMPILE_ENV_ROOT}
    local exclude_cmd=""
    rpmlist_xml_name=$(basename ${RPMLIST_CON} .xml)
    if [[ -s "${WORKSPACE}/${CONFIG_ROOT}/exclude_rpms" ]]; then
        for rpm_name in $(cat "${WORKSPACE}/${CONFIG_ROOT}/exclude_rpms")
        do
            exclude_cmd="${exclude_cmd} -x ${rpm_name}"
        done
    fi
    yum clean all -c "${YUM_CONF}";yum install -c "${YUM_CONF}" --installroot="${WORKSPACE}/${COMPILE_ENV_ROOT}" -y $(cat "${WORKSPACE}/${CONFIG_ROOT}/parsed_${rpmlist_xml_name}" | tr '\n' ' ') -x glibc32 ${exclude_cmd}
}

function make_output() {
    cp ${BUILD_ROOT}/utils/chroot.sh ${WORKSPACE}/${COMPILE_ENV_ROOT}
    pushd ${WORKSPACE}
        echo "/usr/lib" >> "${COMPILE_ENV_ROOT}/etc/ld.so.conf";echo "/usr/lib64" >> "${COMPILE_ENV_ROOT}/etc/ld.so.conf";echo "ldconfig" >> "${COMPILE_ENV_ROOT}/etc/profile";echo "unset PROMPT_COMMAND" >> "${COMPILE_ENV_ROOT}/etc/profile";echo "update-ca-trust" >> "${COMPILE_ENV_ROOT}/etc/profile"
        rm -rf "${COMPILE_ENV_ROOT}"/var/cache/ldconfig/aux-cache;rm -rf "${COMPILE_ENV_ROOT}"/var/log/*;rm -rf "${COMPILE_ENV_ROOT}"/usr/lib/fontconfig/cache/*.cache-7;rm -rf "${COMPILE_ENV_ROOT}"/var/lib/dnf/*;rm -rf "${COMPILE_ENV_ROOT}"/etc/pki/ca-trust/extracted/java/cacerts;rm -rf "${COMPILE_ENV_ROOT}"/var/cache/yum/*;rm -rf "${COMPILE_ENV_ROOT}"/etc/ld.so.cache;rm -rf "${COMPILE_ENV_ROOT}"/var/lib/yum/;rm -rf "${COMPILE_ENV_ROOT}"/var/lib/systemd/catalog/database;rm -rf "${COMPILE_ENV_ROOT}"/usr/share/fonts/dejavu/.uuid;rm -rf "${COMPILE_ENV_ROOT}"/usr/share/fonts/cantarell/.uuid;rm -rf "${COMPILE_ENV_ROOT}"/etc/dconf/db/site;rm -rf "${COMPILE_ENV_ROOT}"/etc/dconf/db/local;rm -rf "${COMPILE_ENV_ROOT}"/etc/dconf/db/distro;rm -rf "${COMPILE_ENV_ROOT}"/usr/share/icons/hicolor/icon-theme.cache;rm -rf "${COMPILE_ENV_ROOT}"/usr/share/icons/Adwaita/icon-theme.cache;rm -rf "${COMPILE_ENV_ROOT}"/var/cache/dnf/*
        output_name="${PRODUCT_NAME}-${VERSION}"
        tar -cf - "${COMPILE_ENV_ROOT}/" | pigz > "${output_name}.tar.gz" &
        wait;chroot "${COMPILE_ENV_ROOT}" /bin/bash -c "rpm -qai|grep 'Source RPM'" > tmp;cat tmp|awk '{print $4}'|sort|uniq > "${output_name}"_source.rpmlist
        chroot "${COMPILE_ENV_ROOT}" /bin/bash -c "rpm -qa" > tmp;cat tmp|sort|uniq > "${output_name}"_binary.rpmlist
        local mkiso_time=$(date +%Y-%m-%d-%H-%M)
        result_path="${BUILD_ROOT}/result/${mkiso_time}"
        copy_file_to_result -t ${result_path} "${output_name}.tar.gz" "${output_name}"_binary.rpmlist "${output_name}"_source.rpmlist
    popd
}

function fn_main() {
    make_clean
    parse_params $@
    if [[ $? -ne 0 ]];then
        echo "parse params failed"
        return 1
    fi
    parse_rpmlist
    if [[ $? -ne 0 ]];then
        echo "parse rpmlist failed"
        return 1
    fi
    install_rpm
    if [[ $? -ne 0 ]];then
        echo "install rpm failed"
        return 1
    fi
    make_output
    if [[ $? -ne 0 ]];then
        echo "make output failed"
        return 1
    fi
    echo "make compile_env success"
    make_clean
}

fn_main $@

