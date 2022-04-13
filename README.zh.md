# oemaker

#### 介绍

`oemaker`源码包拥有两部分功能：iso 格式光盘映像的制作和裁剪。相应地，`oemaker` 源码包会生成两个软件包：`oemaker` 和 `isocut`。

生成的二进制 RPM 包 `oemaker` 是用于制作 DVD 光盘映像的构建工具，可制作的映像包括 standard iso、debug iso、source iso、everything iso、everything source iso、everything debug iso 和 netinst iso。

生成的二进制 RPM 包 `isocut` 是用于裁剪光盘映像的构建工具，支持在 RPM 包级别进行裁剪。

#### 安装教程

可以使用 `rpm` 或 `dnf` 软件包管理器命令通过 openEuler repository 来安装 `oemaker` 和 `isocut`。

使用 `dnf` 安装 `oemaker`
```sh
dnf install -y oemaker
```

使用 `dnf` 安装 `isocut`
```sh
dnf install -y isocut
```

#### 使用说明

一般要求磁盘空间大于 50G。

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

isocut <font color=#0000FF >_[-h] [-t temporary path] [-r extern rpm path] origin-iso dest-iso_</font>

  positional arguments:

    origin-iso    origin iso image
    dest-iso      destination iso image

  optional arguments:

    -t    the temporary path which must be an absolute path and must be greater than 8g
    -r    extern rpm packages path
    -h    show the help message and exit