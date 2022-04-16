#!/usr/bin/python
# -*- coding:utf-8 -*-
"""
Copyright (c) Huawei Technologies Co., Ltd. 2018-2019. All rights reserved.
oemaker licensed under the Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
    http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
PURPOSE.
See the Mulan PSL v2 for more details.
Author: zhuchunyi
Create: 2021-03-17
Description: Used for iso tailoring at the rpm package level
"""

import argparse
import fcntl
import os
import tempfile
import subprocess
import signal
import xml.etree.cElementTree as ET
import shlex
import traceback

# 工具清单
NECESSARY_TOOLS = (
    'yum',
    'repoclosure',
    'yumdownloader',
    'createrepo',
    'genisoimage',
    'mount',
    'umount',
    'file')

EXCLUDE_DIR_REPODATA = "repodata"
EXCLUDE_DIR_PACKAGES = "Packages"
ISOLINUX_CFG = "isolinux/isolinux.cfg"
EFILINUX_CFG = "EFI/BOOT/grub.cfg"
KS_NAME = "_custom.ks"
DUMMY_FILES = ('images/boot.iso', 'extra')
LOCK_FILE = "/var/lock/isocut.lock"
RESULT = 0

# 锁处理
class FLOCK(object):
    def __init__(self, name):
        self.fobj = open(name, 'w')

    def lock(self):
        try:
            fcntl.lockf(self.fobj.fileno(), fcntl.LOCK_EX)
            return True
        except BaseException:
            return False

    def unlock(self):
        self.fobj.close()
        print('isocut.lock unlocked ...')

class IConfig(object):
    def __init__(self):
        self.config_path = "/etc/isocut"
        self.config_rpm_list = self.config_path + "/rpmlist"
        self.config_repodata_template = self.config_path + "/repodata.template"
        self.cache_path = "/var/run/isocut"
        self.yum_conf = self.cache_path + "/yum.conf"
        self.repo_conf = self.cache_path + "/repo.d/isocut.repo"
        self.mkdir_flag = False
        self.src_iso = None
        self.dest_iso = None
        self.iso_desc = None
        self.ks_file = None
        self.rpm_path = None
        self.temp_path = None
        self.temp_path_old_image = None
        self.temp_path_new_image = None
        self.temp_path_min_size = 8 * 1024 * 1024 * 1024

    @classmethod
    def run_cmd(cls, cmd):
        cmd = shlex.split(cmd)
        res = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        sout = res.communicate()
        return res.returncode, sout[0].decode()

    def getinfo(self):
        pass

# 创建ICONFIG对象
ICONFIG = IConfig()

def split_string(start_char, end_char, instring):
    char_start = instring.find(start_char)
    if char_start >= 0:
        char_start += len(start_char)
        end_char = instring.find(end_char, char_start)
    if end_char >= 0:
        return instring[char_start:end_char].strip()

def get_iso_desc():
    cmd = "file {0}".format(ICONFIG.src_iso)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        return 1

    ICONFIG.iso_desc = split_string("'", "'", ret[1])
    return 0

def check_user():
    if os.getuid() != 0:
        print("This tool need root privilege!!")
        return 1

    return 0

def check_tools():
    flag = True
    for tool in NECESSARY_TOOLS:
        cmd = "which {0}".format(tool)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            flag = False
            print("Need tool \"%s\"" % tool)

    if not flag:
        print("Lack necessary tool!!")
        return 2

    return 0

def check_input():
    parser = argparse.ArgumentParser(description='Cut openEuler iso to small one')
    parser.add_argument("source_iso", help="source iso image")
    parser.add_argument("dest_iso", help="destination iso image")
    parser.add_argument("-t", metavar="temporary_path", default="/tmp", help="temporary path")
    parser.add_argument("-r", metavar="rpm_path", help="extern rpm packages path")
    parser.add_argument("-k", metavar="file_path", help="kickstart file")

    args = parser.parse_args()
    ICONFIG.src_iso = args.source_iso
    ICONFIG.dest_iso = args.dest_iso
    ICONFIG.temp_path = args.t
    ICONFIG.rpm_path = args.r
    ICONFIG.ks_file = args.k

    if ICONFIG.src_iso is None or ICONFIG.dest_iso is None:
        print("Must specify source iso image and destination iso image")
        return 3

    if not os.path.isfile(ICONFIG.src_iso):
        print("Source iso image not exist!!")
        return 3

    if ICONFIG.rpm_path is not None:
        if not os.path.exists(ICONFIG.rpm_path):
            print("RPM path do not exist!!")
            return 3
        ICONFIG.rpm_path = os.path.realpath(ICONFIG.rpm_path)

    if ICONFIG.ks_file is not None:
        if not os.path.isfile(ICONFIG.ks_file):
            print("Kickstart file do not exist!!")
            return 3
        ICONFIG.ks_file = os.path.realpath(ICONFIG.ks_file)

    if ICONFIG.temp_path and not os.path.exists(ICONFIG.temp_path):
        os.makedirs(ICONFIG.temp_path)
        ICONFIG.mkdir_flag = True

    st_fs = os.statvfs(ICONFIG.temp_path)
    if (st_fs.f_frsize * st_fs.f_bavail) < ICONFIG.temp_path_min_size:
        print("Temporary path need at least 8G size!!")
        return 3

    ICONFIG.temp_path_old_image = ICONFIG.temp_path + \
        "/" + next(tempfile._get_candidate_names())
    ICONFIG.temp_path_new_image = ICONFIG.temp_path + \
        "/" + next(tempfile._get_candidate_names())

    return 0

def init_workspace():
    cmd = "rm -rf {0} {1}".format(ICONFIG.temp_path_old_image, ICONFIG.temp_path_new_image)
    ret = ICONFIG.run_cmd(cmd)
    os.makedirs(ICONFIG.temp_path_old_image)
    os.makedirs(ICONFIG.temp_path_new_image)
    cmd = "mount -o loop {0} {1}".format(ICONFIG.src_iso, ICONFIG.temp_path_old_image)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("Mount source iso image failed")
        print(ret[1])
        return 4

    print("Copying basic part of iso image ...")
    for path in os.listdir(ICONFIG.temp_path_old_image):
        if path == EXCLUDE_DIR_REPODATA or path == EXCLUDE_DIR_PACKAGES:
            continue
        cmd = "cp -a {0}/{1} {2}".format(ICONFIG.temp_path_old_image,
                                         path, ICONFIG.temp_path_new_image)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            print("Copy from {0}/{1} to {2} failed!!".format(
                ICONFIG.temp_path_old_image, path, ICONFIG.temp_path_new_image))
            return 4

    for dfile in DUMMY_FILES:
        dfile = ICONFIG.temp_path_new_image + "/" + dfile
        if os.path.isfile(dfile):
            os.remove(dfile)
        elif os.path.isdir(dfile):
            __import__('shutil').rmtree(dfile)

    os.makedirs(ICONFIG.temp_path_new_image + "/" + EXCLUDE_DIR_REPODATA)
    os.makedirs(ICONFIG.temp_path_new_image + "/" + EXCLUDE_DIR_PACKAGES)

    return 0

def create_yum_conf():
    try:
        yum_conf = open(ICONFIG.yum_conf, "w+")
        yum_conf.write("[main]\n")
        yum_conf.write("reposdir=%s\n" % os.path.dirname(ICONFIG.repo_conf))
        yum_conf.write("cachedir=%s\n" % ICONFIG.cache_path)
        yum_conf.write("keepcache=0\n")
        yum_conf.write("logfile=/var/log/yum.log\n")
        yum_conf.write("gpgcheck=0\n")
        yum_conf.write("exactarch=1\n")
        yum_conf.write("plugins=1\n")
        yum_conf.write("installonly_limit=5\n")
        yum_conf.write("obsoletes=1\n")
        yum_conf.close()
    except BaseException:
        print("Create %s for isocut failed!!" % ICONFIG.yum_conf)
        return -1
    finally:
        print("Finish create yum conf")
    return 0

def create_repo_conf():
    if ICONFIG.rpm_path is not None:
        cmd = "createrepo {0}".format(ICONFIG.rpm_path)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            print("Create extern rpm repo failed!!")
            return -1

    try:
        if not os.path.exists(os.path.dirname(ICONFIG.repo_conf)):
            os.makedirs(os.path.dirname(ICONFIG.repo_conf))
        repo_conf = open(ICONFIG.repo_conf, "w+")
        repo_conf.write("[isocut]\n")
        repo_conf.write("name=isocut\n")
        repo_conf.write("baseurl=file://%s\n" % ICONFIG.temp_path_old_image)
        repo_conf.write("gpgcheck=0\n")
        repo_conf.write("enabled=1\n")
        repo_conf.write("priority=2\n")
        if ICONFIG.rpm_path is not None:
            repo_conf.write("[extern]\n")
            repo_conf.write("name=extern\n")
            repo_conf.write("baseurl=file://%s\n" % ICONFIG.rpm_path)
            repo_conf.write("gpgcheck=0\n")
            repo_conf.write("enabled=1\n")
            repo_conf.write("priority=1\n")
        repo_conf.close()
    except BaseException:
        print("Create %s for isocut failed!!" % ICONFIG.repo_conf)
        return -1
    finally:
        print("finished")

    return 0

# 安装额外的RPM包
def select_rpm():
    cmd = "rm -rf {0}".format(ICONFIG.cache_path)
    ret = ICONFIG.run_cmd(cmd)
    os.makedirs(ICONFIG.cache_path)

    ret = create_yum_conf()
    if ret != 0:
        return 5

    ret = create_repo_conf()
    if ret != 0:
        return 5

    rpm_list_file = open(ICONFIG.config_rpm_list, "r+")
    rpm_list = ""
    for line in rpm_list_file:
        if not (line is None or line.strip() == ""):
            rpm_list += " %s" % line[:-1].strip()
    cmd = "yumdownloader -y --resolve -c {0} --installroot {1} --destdir {2}/{3} {4}".format(
        ICONFIG.yum_conf, ICONFIG.cache_path, ICONFIG.temp_path_new_image,
        EXCLUDE_DIR_PACKAGES, rpm_list)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0 or "conflicting requests" in ret[1]:
        print("Select rpm failed!!")
        print(ret[1])
        return 5

    return 0

# 格式化XML文件
def indent(elem, level=0):
    i = "\n" + level * "  "
    length = len(elem)
    if length:
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elems in elem:
            indent(elems, level + 1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def regen_repodata():
    product_xml = ICONFIG.temp_path_new_image + \
        "/" + EXCLUDE_DIR_REPODATA + "/product.xml"
    tree = ET.parse(ICONFIG.config_repodata_template)
    root = tree.getroot()
    packlist = root.find('group/packagelist')
    if packlist is None:
        print("Can't find packagelist, illegal template!!")
        return 6
    with open(ICONFIG.config_rpm_list) as fp_rpm:
        for line in fp_rpm:
            if line is None or line.strip() == "":
                continue
            pack = ET.SubElement(packlist, 'packagereq', type='default')
            pack.text = line[:-1].strip()
            if os.uname()[-1].strip() == 'x86_64':
                pack.text = pack.text.split(".x86_64")[0]
            elif os.uname()[-1].strip() == 'aarch64':
                pack.text = pack.text.split(".aarch64")[0]
            pack.text = pack.text.split(".noarch")[0]
        fp_rpm.close()

    indent(root)
    tree.write(product_xml, encoding="UTF-8", xml_declaration=True)
    with open(product_xml, 'r+') as f_product:
        contents = f_product.readlines()
        contents.insert(1,
                        "<!DOCTYPE comps\n  PUBLIC '-//Huawei "
                        "Technologies Co. Ltd.//DTD Comps info//EN'\n  'comps.dtd'>\n")
        contents_str = "".join(contents)
        f_product.seek(0, 0)
        f_product.write(contents_str)
        f_product.close()
    cmd = "createrepo -g {0} {1}".format(product_xml, ICONFIG.temp_path_new_image)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("Regenerate repodata failed!!")
        print(ret[1])
        return 6

    return 0

# 检查裁剪的ISO所需的rpm包的依赖关系
def check_deps():
    try:
        repo_conf = open(ICONFIG.repo_conf, "w+")
        repo_conf.write("[check_iso]\n")
        repo_conf.write("name=check_iso\n")
        repo_conf.write("baseurl=file://%s\n" % ICONFIG.temp_path_new_image)
        repo_conf.write("gpgcheck=0\n")
        repo_conf.write("enabled=1\n")
        repo_conf.close()
    except BaseException:
        print("Check deps update yum conf failed!!")
        return 9
    finally:
        cmd = "repoclosure -c {0}".format(ICONFIG.yum_conf)
        ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print(ret[1])
        return 9

    return 0

def remake_iso():
    if ICONFIG.ks_file is not None:
        cmd = "cp {0} {1}/{2}".format(ICONFIG.ks_file, ICONFIG.temp_path_new_image, KS_NAME)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            print("Copy kickstart file failed!!")
            return 7
        if os.uname()[-1].strip() == 'x86_64':
            sed_cmd = r"sed -i '/append/ s/$/ inst.ks=cdrom:\/dev\/cdrom:\/" + KS_NAME + \
                " inst.multilib/g' " + ICONFIG.temp_path_new_image + "/" + ISOLINUX_CFG
            ret = ICONFIG.run_cmd(sed_cmd)
            if ret[0] != 0:
                print("Set kickstart file failed!!")
                return 7

        sed_cmd = r"sed -i '/inst.stage2/ s/$/ inst.ks=cdrom:\/dev\/cdrom:\/" + KS_NAME + \
            " inst.multilib/g' " + ICONFIG.temp_path_new_image + "/" + EFILINUX_CFG
        ret = ICONFIG.run_cmd(sed_cmd)
        if ret[0] != 0:
            print("Set efi kickstart file failed!!")
            return 7

    if os.uname()[-1].strip() == 'x86_64':
        make_iso_cmd = "genisoimage -R -J -T -r -l -d -input-charset utf-8 " \
                       "-joliet-long -allow-multidot -allow-leading-dots -no-bak -V \"%s\"" \
                       " -o \"%s\" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot " \
                       "-boot-load-size 4 -boot-info-table -eltorito-alt-boot " \
                       "-e images/efiboot.img -no-emul-boot \"%s\"" % (
                           ICONFIG.iso_desc, ICONFIG.dest_iso, ICONFIG.temp_path_new_image)
    elif os.uname()[-1].strip() == 'aarch64':
        make_iso_cmd = "genisoimage -R -J -T -r -l -d -input-charset utf-8 " \
                       "-joliet-long -allow-multidot -allow-leading-dots -no-bak -V \"%s\" " \
                       "-o \"%s\" -e images/efiboot.img -no-emul-boot \"%s\"" % (
                           ICONFIG.iso_desc, ICONFIG.dest_iso, ICONFIG.temp_path_new_image)
    dest_iso_path = os.path.dirname(ICONFIG.dest_iso)
    if not (dest_iso_path is None or dest_iso_path ==
            "") and not os.path.exists(dest_iso_path):
        os.makedirs(os.path.dirname(ICONFIG.dest_iso))
    ret = ICONFIG.run_cmd(make_iso_cmd)
    if ret[0] != 0:
        print("Remake iso image failed!!")
        print(ret[1])
        return 7

    return 0

def add_checksum():
    cmd = "implantisomd5 {0}".format(ICONFIG.dest_iso)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("Add checksum failed!!")
        return 8

    return 0

def add_sha256sum():
    cmd = "sha256sum {0}".format(ICONFIG.dest_iso)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("Add sha256sum failed: {0}!!".format(ret))
        return 8

    with open("{0}.sha256sum".format(ICONFIG.dest_iso), "w") as f_sha256sum:
        f_sha256sum.write(ret[1])
    return 0

def do_clean():
    cmd = "umount {old}".format(old=ICONFIG.temp_path_old_image)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("umount {old} failed!!".format(old=ICONFIG.temp_path_old_image))
    cmd = "rm -rf {old} {new} {cache}".format(old=ICONFIG.temp_path_old_image,
        new=ICONFIG.temp_path_new_image, cache=ICONFIG.cache_path)
    ret = ICONFIG.run_cmd(cmd)
    if ret[0] != 0:
        print("rm -rf {old} {new} {cache} failed!!".format(
            old=ICONFIG.temp_path_old_image,
            new=ICONFIG.temp_path_new_image,
            cache=ICONFIG.cache_path))
    if ICONFIG.mkdir_flag:
        cmd = "rm -rf {0}".format(ICONFIG.temp_path)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            print("rm -rf {0} failed!!".format(ICONFIG.temp_path))
    if ICONFIG.rpm_path is not None:
        cmd = "rm -rf {0}/repodata".format(ICONFIG.rpm_path)
        ret = ICONFIG.run_cmd(cmd)
        if ret[0] != 0:
            print("rm -rf {0}/repodata failed!!".format(ICONFIG.rpm_path))

    return 0

def main():
    try:
        print("Checking input ...")
        if check_input():
            raise Exception('Input illegal')

        print("Checking user ...")
        if check_user():
            raise Exception('Must be root user')

        print("Checking necessary tools ...")
        if check_tools():
            raise Exception('Lack necessary tool')

        print("Initing workspace ...")
        if init_workspace():
            raise Exception('Init workspace failed')

        print("Downloading rpms ...")
        if select_rpm():
            raise Exception('Download rpms failed')

        print("Regenerating repodata ...")
        if regen_repodata():
            raise Exception('Generate repodata failed')

        print("Checking rpm deps ...")
        if check_deps():
            raise Exception('Check rpm deps failed')

        print("Getting the description of iso image ...")
        if get_iso_desc():
            raise Exception('Get the description of iso image failed')

        print("Remaking iso ...")
        if remake_iso():
            raise Exception('Make iso failed')

        print("Adding checksum for iso ...")
        if add_checksum():
            raise Exception('Add checksum failed')

        print("Adding sha256sum for iso ...")
        if add_sha256sum():
            raise Exception('Add sha256sum failed')
    except Exception as error:
        print(repr(error))
        print("Excution failed!!")
        traceback.print_exc()
        do_clean()
        return -1
    print("ISO cutout succeeded, enjoy your new image \"%s\"" % ICONFIG.dest_iso)
    do_clean()
    return 0

def signal_handler():
    do_clean()

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGQUIT, signal_handler)

if __name__ == "__main__":
    LOCKER = FLOCK(LOCK_FILE)
    LOCKER.lock()
    os.umask(0o77)
    RESULT = main()
    LOCKER.unlock()
    exit(RESULT)
