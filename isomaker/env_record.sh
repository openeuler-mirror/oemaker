:<<!
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2022. All rights reserved.
 * oemaker licensed under the Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *     http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
 * PURPOSE.
 * See the Mulan PSL v2 for more details.
 * Author:
 * Create: 2022-03-08
 * Description: provide container buffer functions
!

#!/bin/bash

set -e
function env_record()
{
    # 记录环境
    selinux_flag=-1
    se_status=$(getenforce)
    if [ "$se_status" == "Enforcing" ]; then
        selinux_flag=1
    elif [ "$se_status" == "Permissive" ]; then
        selinux_flag=0
    else
        echo "Selinux status is $se_status, can't restore"
        return 0
    fi

    env_value_name="SELINUX_FLAG"
    if [ "$selinux_flag" -ne -1 ]; then
        # 先删除(/d)环境变量，再添加环境变量
        sed -i "/${env_value_name}=.*/d" /etc/profile
        echo "export ${env_value_name}=${selinux_flag}" >> /etc/profile
    fi

    echo "the current env has been recorded. "
    echo "If oemaker run failed, run the following cmd restore current env"
    echo "sh ${CPATH}/env_restore.sh"
}
