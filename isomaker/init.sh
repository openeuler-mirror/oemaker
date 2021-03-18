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
function oemaker_usage()
{
    cat << EOF
Usage: oemaker [-h] [-t Type] [-p Product] [-v Version] [-r RELEASE] [-s REPOSITORY]

optional arguments:
    -t Type        ISO Type, include standard debug source everything everything_debug everything_src and netinst
    -p Product     Product Name, such as: openEuler
    -v Version     version identifier
    -r RELEASE     release information
    -s REPOSITORY  source dnf repository address link(may be listed multiple times)
    -h             show the help message and exit
EOF
}

function parse_cmd_line()
{
    #param init
    ARCH="$(uname -m)"
    if [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "x86_64" ];then
        CONFIG_FILE="${CPATH}/config/${ARCH}/standard.conf"
        source "${CONFIG_FILE}"
    else
        echo "unsupported architectures: ${ARCH}"
        return 1
    fi
    PRODUCT="${CONFIG_PRODUCT}"
    VERSION="${CONFIG_VERSION}"
    RELEASE="${CONFIG_RELEASE}"
    REPOS1="${CONFIG_YUM_REPOS}"

    # parse input params
    while getopts ":p:v:r:s:t:h" opt
    do
        case "$opt" in
            p)
                PRODUCT="$OPTARG"
            ;;
            v)
                VERSION="$OPTARG"
            ;;
            r)
                RELEASE="$OPTARG"
            ;;
            s)
                REPOS1="$OPTARG"
            ;;
            t)
                ISO_TYPE="$OPTARG"
            ;;
            h)
                oemaker_usage
                exit 0
            ;;
            ?)
                echo "error: please check the params."
                oemaker_usage
                return 1
            ;;
        esac
    done

    for typename in standard source debug everything_debug everything everything_src netinst
    do
        if [ "${typename}" == "${ISO_TYPE}" ];then
            return 0
        fi
    done

    echo "unsupported iso type: ${ISO_TYPE}"
    echo "supported iso types: standard source and debug"
    return 1
}

function global_var_init()
{
    if [ "X$CONFIG_FILE" != "X" -a -f "$CONFIG_FILE" ];then
        source "${CONFIG_FILE}";
    fi

    TYPE="iso"
    VARIANT="Server"
    BUILD="${OUTPUT_DIR}"/tmp
    SRC_DIR="$OUTPUT_DIR"/tmp/src
    DBG_DIR="$OUTPUT_DIR"/tmp/dbg
    EVERY_DIR="$OUTPUT_DIR"/tmp/everything
    EVERY_SRC_DIR="$OUTPUT_DIR"/tmp/everything_src
    EVERY_DEBUG_DIR="$OUTPUT_DIR"/tmp/everything_debug

    if [ -n "${RELEASE}" ];then
        RELEASE_NAME="${PRODUCT}-${VERSION}-${RELEASE}-${ARCH}"
        STANDARD_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-${ARCH}-dvd.iso"
        SRC_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-source-dvd.iso"
        DBG_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-debug-${ARCH}-dvd.iso"
        EVE_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-everything-${ARCH}-dvd.iso"
        EVE_DEBUG_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-everything-debug-${ARCH}-dvd.iso"
        EVE_SRC_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-everything-source-dvd.iso"
        NETINST_ISO_NAME="${PRODUCT}-${VERSION}-${RELEASE}-netinst-${ARCH}-dvd.iso"
    else
        RELEASE_NAME="${PRODUCT}-${VERSION}-${ARCH}"
        STANDARD_ISO_NAME="${PRODUCT}-${VERSION}-${ARCH}-dvd.iso"
        SRC_ISO_NAME="${PRODUCT}-${VERSION}-source-dvd.iso"
        DBG_ISO_NAME="${PRODUCT}-${VERSION}-debug-${ARCH}-dvd.iso"
        EVE_ISO_NAME="${PRODUCT}-${VERSION}-everything-${ARCH}-dvd.iso"
        EVE_DEBUG_ISO_NAME="${PRODUCT}-${VERSION}-everything-debug-${ARCH}-dvd.iso"
        EVE_SRC_ISO_NAME="${PRODUCT}-${VERSION}-everything-source-dvd.iso"
        NETINST_ISO_NAME="${PRODUCT}-${VERSION}-netinst-${ARCH}-dvd.iso"
    fi

    [ ! -d "${BUILD}" ] && mkdir -p "${BUILD}"

    [ -d "${BUILD}"/iso ] && rm -rf "${BUILD}"/iso

    set +e
    setenforce 0

    if [ "X$CONFIG_FILE" != "X" ];then
        YUMREPO="$CONFIG_YUM_REPOS"
        CONFIG="$CONFIG_PACKAGES_LIST_FILE"
    else
        YUMREPO="-s $YUM_REPO"
        CONFIG=""
    fi
    REPOS=$(echo "$REPOS1")
    if [ "X$REPOS" != "X" ];then
        REPOS=$(echo " ""${REPOS}" | sed 's/ / -s /g')
        YUMREPO="${REPOS}"
    fi
    set -e
    return 0
}

function init_config()
{
    [ -f "${BUILD}"/isopackage.sdf ] && cp "${BUILD}"/isopackage.sdf "${BUILD}"/iso/

    if [ ! -z "$CONFIG_KS_FILE" ]; then
        mkdir -p "${BUILD}"/iso/ks
        cp "$CONFIG_KS_FILE" "${BUILD}"/iso/ks/
    fi
    if [ ! -f "${BUILD}/docs/OpenEuler-Software-License.docx" ]; then
        mkdir -p "${BUILD}"/iso/docs
        cp "${CPATH}"/docs/* "${BUILD}"/iso/docs/
    fi
    return 0
}
