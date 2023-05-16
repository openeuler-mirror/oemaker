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
 * Description: provide common functions
!

#!/bin/bash
set -e

function copy_file_to_result() {
    opt_output="/opt/output"
    if [[ "$1" = "-t" ]];then
        opt_output="$2"
        shift
        shift
    fi
    mkdir -p "${opt_output}"
    for file in $*
    do
        rm -rf "${opt_output}/${file}"
        mv "${file}" "${opt_output}"
    done
}
