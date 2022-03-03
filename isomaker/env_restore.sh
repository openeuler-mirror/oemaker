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
function env_restore()
{
    # 使用环境变量执行恢复
    source /etc/profile >> /dev/null
    if [ "$SELINUX_FLAG" -eq 0 ] || [ "$SELINUX_FLAG" -eq 1 ]; then
        setenforce "${SELINUX_FLAG}"
    else
        echo "/etc/profile have no value: SELINUX_FLAG"
    fi
}

env_restore
