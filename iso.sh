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
function gen_debug_iso()
{
    rm -rf "${BUILD}"/iso/repodata/*
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    rm -rf "$BUILD"/iso/Packages
    mv "$DBG_DIR" "$BUILD"/iso/Packages
    createrepo -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${DBG_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${DBG_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 /result/"${DBG_ISO_NAME}"
    return 0
}

function gen_iso()
{
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 /result/"${ISO_NAME}"
    return 0
}


function gen_src_iso()
{
    set +e
    rm -rf "$BUILD"/iso/Packages
    mv "$SRC_DIR" "$BUILD"/iso/Packages

    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${SRC_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${SRC_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    return 0
}
