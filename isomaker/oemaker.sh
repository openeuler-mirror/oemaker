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
cd /opt/oemaker
REPOS=""
ISO_TYPE="standard"
export OUTPUT_DIR="/result"
export CPATH=$(pwd)

umask 0022

source "${CPATH}"/init.sh
source "${CPATH}"/iso.sh
source "${CPATH}"/rpm.sh
source "${CPATH}"/img_repo.sh
source "${CPATH}"/make_debug.sh

function mkclean()
{
    if [ -d repos.old ];then
        rm -rf /etc/yum.repos.d && mv repos.old /etc/yum.repos.d
    fi

    [ -d "$BUILD" ] && rm -rf "$BUILD"
}

function mk_oe_main()
{
    parse_cmd_line "$@"
    if [ $? -ne 0 ]; then
        echo "parse params failed"
        return 1
    fi

    echo "Initializing variables..."
    global_var_init
    if [ $? -ne 0 ]; then
        echo "init env failed"
        return 1
    fi

    if [ "${ISO_TYPE}" == "netinst" ]; then
        create_install_img
        init_config
        if [ $? -ne 0 ]; then
            echo "init config failed"
            return 1
        fi
        gen_netinst_iso
        if [ $? -ne 0 ]; then
            echo "create netinst iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${NETINST_ISO_NAME}"
        return 0
    fi

    create_install_img

    echo "Creating repos..."
    create_repos
    if [ $? -ne 0 ]; then
        echo "create repo failed"
        return 1
    fi

    echo "Downloading rpms..."
    download_rpms
    if [ $? -ne 0 ]; then
        echo "down rpms failed"
        return 1
    fi

    echo "Initializing config..."
    wait && cat lorax.logfile
    init_config
    if [ $? -ne 0 ]; then
        echo "init config failed"
        return 1
    fi

    echo "Getting rpm public key..."
    get_rpm_pub_key
    if [ $? -ne 0 ]; then
        echo "get rpm pub key failed"
        return 1
    fi

    echo "Waiting for lorax to finish..."
    if [ "${ISO_TYPE}" == "debug" ]; then
        gen_debug_iso
        if [ $? -ne 0 ]; then
            echo "create debug iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${DBG_ISO_NAME}"
    elif [ "${ISO_TYPE}" == "standard" ]; then
        gen_standard_iso
        if [ $? -ne 0 ]; then
            echo "create install iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${STANDARD_ISO_NAME}"
    elif [ "${ISO_TYPE}" == "source" ]; then
        gen_src_iso
        if [ $? -ne 0 ]; then
            echo "create source iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${SRC_ISO_NAME}"
    elif [ "${ISO_TYPE}" == "everything" ]; then
        gen_everything_iso
        if [ $? -ne 0 ]; then
            echo "create everything iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${EVE_ISO_NAME}"
    elif [ "${ISO_TYPE}" == "everything_debug" ]; then
        gen_everything_debug_iso
        if [ $? -ne 0 ]; then
            echo "create everything debug iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${EVE_DEBUG_ISO_NAME}"
    elif [ "${ISO_TYPE}" == "everything_src" ]; then
        gen_everything_src_iso
        if [ $? -ne 0 ]; then
            echo "create everything source iso failed"
            return 1
        fi
        ls "${OUTPUT_DIR}/${EVE_SRC_ISO_NAME}"
    fi
    mkclean
    return 0
}

mk_oe_main "$@"
if [ $? -ne 0 ]; then
    echo "make iso failed"
    exit 1
fi
