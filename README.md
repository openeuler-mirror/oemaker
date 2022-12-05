# oemaker

#### 介绍

源码包oemaker包括两部分功能：iso制作和iso裁剪。相应的，会构建生成两个二进制RPM包：oemaker和isocut.

生成的二进制RPM包oemaker是一款用于构建DVD iso的工具，包括标准iso，debug iso, source iso, everything iso, everything debug iso, everything source, edge computing iso and netinst iso等

生成的二进制RPM包isocut是一款用于iso裁剪的构建工具，支持RPM包级别的裁剪。

#### 安装教程

可以用`rpm`或`dnf`命令通过openEuler repository来安装`oemaker`和`isocut`包。

用dnf命令安装`oemaker`方式：
```sh
dnf install -y oemaker
```

用dnf命令安装`isocut`方式：
```sh
dnf install -y isocut
```

#### 使用说明

一般要求磁盘空间大于50G


#### 使用方法

##### oemaker

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

##### isocut

isocut <font color=#0000FF >_[-h] [-t temporary path] [-r extern rpm path] [-k kickstart file path] origin-iso dest-iso_</font>

  positional arguments:

    origin-iso    origin iso image
    dest-iso      destination iso image

  optional arguments:

    -t    the temporary path which must be an absolute path and must be greater than 8g
    -r    extern rpm packages path
    -k    Kickstart file path
    -h    show the help message and exit
