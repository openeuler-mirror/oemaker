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
function create_install_img()
{
    echo "$YUMREPO" > yumrepo.file
    lorax --isfinal -p "${PRODUCT}" -v "${VERSION}${RELEASE}" -r "${RELEASE}" --sharedir 80-openeuler --rootfs-size=3 --buildarch="$ARCH" $(cat yumrepo.file) --nomacboot --noupgrade "${BUILD}"/iso > lorax.logfile 2>&1

    if [ $? != 0 ] ; then
        cat lorax.logfile
        exit 1
    fi
}

function create_repos()
{
    if [ -d /etc/yum.repos.d ];then
        mv /etc/yum.repos.d repos.old && mkdir -p /etc/yum.repos.d/
    fi

    repos=($(echo "$YUMREPO" | sed 's/-s//g'))

    for repo in  ${repos[@]}
    do
        yum-config-manager  --add-repo "$repo"
    done

    yum clean all
}
