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
 * Description: provide chroot functions
!

#!/bin/bash

CHROOT_DIR=$(dirname $(readlink -f $0))

USAGE="
Usage: sh $0 [option]

Warning: This script cannot be used in compile_env
Options:
        init         init compile_env and mount the required directories
                     no option default to init
        umount       clean up compile_env
        --help       Display help information
Example:
        enter     compile_env: sh $0
                                           sh $0 init
        umount compile_env: sh $0 umount
"

function fn_umount() {
    i=0
    while tac /proc/mounts | grep "${CHROOT_DIR}" &> /dev/null
    do
        while read line;
        do
            if echo $line | grep ${CHROOT_DIR} &> /dev/null; then
                dir=$(echo $line | awk '{print $2}')
                umount --lazy $dir
            fi
        done < /proc/mounts
        ((i++))
        if [[ $i -ge 8 ]]; then
            break
        fi
    done
}

function fn_init() {
    tac /proc/mounts | grep "${CHROOT_DIR}/dev" &> /dev/null
    if [[ $? -ne 0 ]]; then
        mount --bind /dev ${CHROOT_DIR}/dev/
    fi
    tac /proc/mounts | grep "${CHROOT_DIR}/sys" &> /dev/null
    if [[ $? -ne 0 ]]; then
        mount --bind /sys ${CHROOT_DIR}/sys/
    fi
    tac /proc/mounts | grep "${CHROOT_DIR}/proc" &> /dev/null
    if [[ $? -ne 0 ]]; then
        mount --bind /proc ${CHROOT_DIR}/proc
    fi
    tac /proc/mounts | grep "${CHROOT_DIR}/dev/pts" &> /dev/null
    if [[ $? -ne 0 ]]; then
        mount -n -tdevpts -omode=0620,gid=5 none ${CHROOT_DIR}/dev/pts
    fi

    chroot ${CHROOT_DIR} /bin/bash --login
}

if [[ ${CHROOT_DIR} == "/" ]]; then
    echo -e "\033[31m\033[01m[ Warning: This script cannot be used in compile_env ]\033[0m"
    printf "%s\\n" "${USAGE}"
    exit 1
fi

if [[ $# -gt 1 ]]; then
    echo -e "\033[31m\033[01m[ missing params, please check it! ]\033[0m"
    printf "%s\\n" "${USAGE}"
    exit 2
fi

if [[ $# -eq 0 ]] || [[ $1 == "init" ]]; then
    fn_init
    trap "sh ${CHROOT_DIR}/chroot.sh umount" EXIT
    exit 0
elif [[ $1 == "umount" ]]; then
    fn_umount
    exit 0
else
    printf "%s\\n" "${USAGE}"
    exit 3
fi
