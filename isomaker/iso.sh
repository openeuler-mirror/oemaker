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
function gen_debug_iso()
{
    rm -rf "${BUILD}"/iso/repodata/*
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    rm -rf "$BUILD"/iso/Packages
    mv "$DBG_DIR" "$BUILD"/iso/Packages
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${DBG_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${DBG_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${DBG_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 "${OUTPUT_DIR}/${DBG_ISO_NAME}"
    return 0
}

function gen_standard_iso()
{
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
        isohybrid -u "${OUTPUT_DIR}/${STANDARD_ISO_NAME}"
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 "${OUTPUT_DIR}/${STANDARD_ISO_NAME}"
    return 0
}

function gen_edge_iso()
{
    set +e
    mkdir -p "${BUILD}"/iso/repodata/
    cp "config/${ARCH}/edge_normal.xml" "${BUILD}"/iso/repodata/
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${EDGE_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${EDGE_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 "${OUTPUT_DIR}/${EDGE_ISO_NAME}"
    return 0
}

function gen_desktop_iso()
{
    set +e
    mkdir -p "${BUILD}"/iso/repodata/
    cp "config/${ARCH}/desktop_normal.xml" "${BUILD}"/iso/repodata/
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${DESKTOP_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${DESKTOP_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 "${OUTPUT_DIR}/${DESKTOP_ISO_NAME}"
    return 0
}

function gen_src_iso()
{
    set +e
    rm -rf "$BUILD"/iso/Packages
    mv "$SRC_DIR" "$BUILD"/iso/Packages
    createrepo -d "$BUILD"/iso
    if [ "$ARCH" == "x86_64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${SRC_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o "${OUTPUT_DIR}/${SRC_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    return 0
}

function gen_everything_iso()
{
    set +e
    rm -rf "${BUILD}"/iso/repodata/*
    rm -rf "$BUILD"/iso/Packages
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    mv "${EVERY_DIR}" "${BUILD}"/iso/Packages
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64"  ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
        isohybrid -u /result/"${EVE_ISO_NAME}"
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 /result/"${EVE_ISO_NAME}"
    return 0
}

function gen_everything_debug_iso()
{
    set +e
    rm -rf "${BUILD}"/iso/repodata/*
    rm -rf "${BUILD}"/iso/Packages
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    mv "${EVERY_DEBUG_DIR}" "${BUILD}"/iso/Packages
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64"  ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_DEBUG_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_DEBUG_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 /result/"${EVE_DEBUG_ISO_NAME}"
    return 0
}

function gen_everything_src_iso()
{
    set +e
    rm -rf "${BUILD}"/iso/repodata/*
    rm -rf "${BUILD}"/iso/Packages
    cp "$CONFIG" "${BUILD}"/iso/repodata/
    mv "${EVERY_SRC_DIR}" "${BUILD}"/iso/Packages
    createrepo -d -g "${BUILD}"/iso/repodata/*.xml "${BUILD}"/iso
    if [ "$ARCH" == "x86_64"  ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_SRC_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
    elif [ "$ARCH" == "aarch64"  ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${EVE_SRC_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1

    fi
    implantisomd5 /result/"${EVE_SRC_ISO_NAME}"
    return 0
}

function gen_netinst_iso()
{
    if [ "$ARCH" == "x86_64"  ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${NETINST_ISO_NAME}" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table  -eltorito-alt-boot -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
        [ $? != 0  ] && return 1
        isohybrid -u /result/"${NETINST_ISO_NAME}"
    elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "loongarch64" ] || [ "$ARCH" == "riscv64" ]; then
        mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -V "${RELEASE_NAME}" -o /result/"${NETINST_ISO_NAME}" -e images/efiboot.img -no-emul-boot "${BUILD}"/iso
    elif [ "$ARCH" == "ppc64le" ]; then
        mkisofs -joliet-long -U -J -R -T -o "${OUTPUT_DIR}/${STANDARD_ISO_NAME}" -part -hfs -r -l -sysid "${SYSID_PPC}" -V "${RELEASE_NAME}" -chrp-boot -hfs-bless boot/grub/powerpc-ieee1275  -no-desktop -allow-multidot "${BUILD}"/iso
        [ $? != 0 ] && return 1
    fi
    implantisomd5 /result/"${NETINST_ISO_NAME}"
    return 0
}

function gen_livecd_iso() {
    #pre
    set +e
    export LD_PRELOAD=libgomp.so.1
    rm -rf /etc/yum.repos.d/EnCloudOS.repo || true

    root_pwd=$(cat config/${ARCH}/livecd/root_pwd)
    if [[ "x${root_pwd}" == "x" ]];then
        echo "error: password config is empty, please check password config in file config/${ARCH}/livecd/root_pwd"
        return 1
    fi
    rpmlist=$(cat config/${ARCH}/livecd/rpmlist)
    if [[ "x${rpmlist}" == "x" ]];then
        echo "error: rpmlist is empty, please check rpmlist in file config/${ARCH}/livecd/rpmlist"
        return 1
    fi
    work_dir="$(pwd)/workspace/"
    cfg_dir="${work_dir}/config"

    if [ -d "${work_dir}" ]; then rm -rf "$work_dir";fi
    mkdir -p $work_dir

    if [ -d "${cfg_dir}" ]; then rm -rf "${cfg_dir}";fi
    mkdir -p "${cfg_dir}"
    mkdir -p /var/adm/fillup-templates/
    cp config/${ARCH}/livecd/livecd_${ARCH}.ks ${cfg_dir}
    sed -i 's#ROOT_PWD#'${root_pwd}'#' ${cfg_dir}/livecd_${ARCH}.ks
    sed -i 's#INSTALL_REPO#'${REPOS1}'#' ${cfg_dir}/livecd_${ARCH}.ks
    for rpm_name in ${rpmlist}
    do
        sed -i '/%packages/a '${rpm_name}'' ${cfg_dir}/livecd_${ARCH}.ks
    done
    rm -rf /usr/share/lorax/templates.d/99-generic/live
    cp -r config/${ARCH}/livecd/live /usr/share/lorax/templates.d/99-generic/
    # build

    livemedia-creator --make-iso --ks=${cfg_dir}/livecd_"${ARCH}".ks --nomacboot --no-virt --project "${LIVE_CD_ISO_NAME}" --releasever "${VERSION}${RELEASE}" --tmp "${work_dir}" --anaconda-arg="--nosave=all_ks" --dracut-arg="--xz" --dracut-arg="--add livenet dmsquash-live convertfs pollcdrom qemu qemu-net" --dracut-arg="--omit" --dracut-arg="plymouth" --dracut-arg="--no-hostonly" --dracut-arg="--debug" --dracut-arg="--no-early-microcode" --dracut-arg="--nostrip"
    [ $? != 0  ] && return 1
    cd ${work_dir}/*/images
    LIVECD_TAR=$(ls *.iso)
    livecd_source_list=$(echo "$LIVE_CD_ISO_NAME"|sed 's/.iso//g')_source.rpmlist
    livecd_binary_list=$(echo "$LIVE_CD_ISO_NAME"|sed 's/.iso//g')_binary.rpmlist
    mv "${LIVECD_TAR}" "${LIVE_CD_ISO_NAME}"
    mkdir -p {rootfs,squa};mount ../LiveOS/squashfs.img squa/;mount squa/LiveOS/rootfs.img rootfs/
    chroot rootfs/ /bin/bash -c "rpm -qai|grep 'Source RPM'" > tmp;cat tmp|awk '{print $4}'|sort|uniq > "$livecd_source_list"
    chroot rootfs/ /bin/bash -c "rpm -qa" > tmp;cat tmp|sort|uniq > "$livecd_binary_list"
    umount rootfs squa
    mkdir -p /result/;rm -rf /result/*;mv "${LIVE_CD_ISO_NAME}" /result
    mv "$livecd_source_list" /result
    mv "$livecd_binary_list" /result
    cd -
    rm -rf ${work_dir}
    implantisomd5 /result/"${LIVE_CD_ISO_NAME}" --force
    return 0
}
