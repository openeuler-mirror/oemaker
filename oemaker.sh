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
cd /opt/oemaker
REPOS=""
export OUTPUT_DIR="/result"
export CPATH=$(pwd)

umask 0022

source "${CPATH}"/init.sh
source "${CPATH}"/iso.sh
source "${CPATH}"/rpm.sh
source "${CPATH}"/img_repo.sh

function mkclean()
{
    rm -rf /etc/yum/repos.d/*
    [ -n "${BUILD}" ] && rm -rf "${BUILD}"
    rm -rf /etc/yum.repos.d && mv repos.old /etc/yum.repos.d
}

function mk_euleros_main()
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

    create_install_img &

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
    if [ "${ISOTYPE}" == "debug" ]; then
        gen_debug_iso
        if [ $? -ne 0 ]; then
            echo "create debug iso failed"
            return 1
        fi
        mkclean
        echo "${OUTPUT_DIR}/${DBG_ISO_NAME}"
    elif [ "${ISOTYPE}" == "standard" ]; then
        gen_iso
        if [ $? -ne 0 ]; then
            echo "create install iso failed"
            return 1
        fi
        mkclean
        echo "${OUTPUT_DIR}/${ISO_NAME}"
   elif [ "${ISOTYPE}" == "source" ]; then
        gen_src_iso
        if [ $? -ne 0 ]; then
            echo "create source iso failed"
            return 1
        fi
        mkclean
        echo "${OUTPUT_DIR}/${SRC_ISO_NAME}"
    fi
    return 0
}

mk_euleros_main "$@"
if [ $? -ne 0 ]; then
    echo "make iso failed"
    exit 1
fi
