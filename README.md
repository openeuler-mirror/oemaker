# oemaker

#### 介绍
oemaker是一款用于构建DVD iso的工具，包括标准iso，debug iso, source iso, everything iso, everything debug iso, everything source iso, edge computing iso and netinst iso等。
oemaker采用的是本地架构的方式进行构建，不支持交叉编译环境构建。
目前，oemkaer支持aarch64和x86_64两个架构的iso制作。

#### 安装教程

可以用rpm命令或dnf包管理命令通过openEuler repository安装oemaker包。

用dnf命令安装方式：
```sh
dnf install -y oemaker
```

#### 使用说明

一般要求磁盘空间大于50G


#### 使用方法

oemaker <font color=#0000FF >_[-h] [-t Type] [-p Product] [-v Version] [-r RELEASE] [-s REPOSITORY]_</font>

    optional arguments:
    -t Type
       ISO Type include standard debug source everything everything_debug everything_src and netinst

    -p Product
       Product Name, such as: openEuler

    -v Version
       version identifier

    -r RELEASE
       release information

    -s REPOSITORY
       source dnf repository address link(may be listed multiple times)

    -h 
       show the help message and exit
