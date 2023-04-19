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

FUNCTION_SELECT=""
FUNCTION_PARAMS=""

umask 0022

function oemaker_usage()
{
    cat << EOF
Usage: oemaker [OPTION...]

Common options:
    -c Function select: isomaker or isocut
    -h Show the help message and exit

Make new ISO image selection options:
    -t ISO Type, include standard debug source everything everything_debug everything_src and netinst
    -p Product Name, such as: openEuler
    -v Version identifier
    -r Release information
    -s Source dnf repository address link(may be listed multiple times

Customize the ISO selection options:
    -t the temporary path which must be an absolute path and must be greater than 8g
    -r The extern rpm packages path
    -k The kickstart file path
    -i The isolinux cfg file path
    -g The grub cfg file path
    -a The anaconda pixmaps file path
EOF
}

function oemaker_parse_func_class()
{
    while getopts "c:ht:p:v:r:s:k:i:g:a:" opt
    do
        case "$opt" in
            c)
                FUNCTION_SELECT="$OPTARG"
                return 0
            ;;
            h)
                oemaker_usage
                exit 0
            ;;
        esac
    done

    return 1
}

function oemaker_main()
{
    oemaker_parse_func_class "$@"
    if [ $? -ne 0 ]; then
        echo "Please check the parameters."
        echo "You can use the -h command to view the help information."
        return 1
    fi

    FUNCTION_PARAMS=${@//$FUNCTION_SELECT/}
    FUNCTION_PARAMS=${FUNCTION_PARAMS//-c/}
    $FUNCTION_SELECT $FUNCTION_PARAMS
    return 0
}

oemaker_main "$@"
