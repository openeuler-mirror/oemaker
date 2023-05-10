# oemaker

#### Description

The source package `oemaker` has two functions: ISO making and splitting. Accordingly, two software packages are generated: `oemaker` and `isocut`.

The generated binary RPM `oemaker` is a build tool for making DVD ISOs, including the Standard ISO, Debug ISO, Source ISO, Everything ISO, Everything Source ISO, Everything Debug ISO, and Netinstall ISO.

The generated binary RPM `isocut` is a build tool for ISO splitting, which supports only package-level RPM.

#### Installation

To install `oemaker` and `isocut`, you can use the `rpm` or `dnf` package manager command with the openEuler repository.

Install `oemaker` with `dnf`
```sh
dnf install -y oemaker
```

Install `isocut` with `dnf`
```sh
dnf install -y isocut
```

#### Instruction

Generally, the disk space must be more than 50 GB.

#### Usage

##### oemaker

oemaker <font color=#0000FF >_[-h] [-t Type] [-p Product] [-v Version] [-r RELEASE] [-s REPOSITORY]_</font>

  Optional arguments:

    -t    ISO type, including standard, debug, source, everything, everything_debug, everything_src, and netinst 

    -p    Product name, for example, openEuler

    -v    Version number

    -r    Release information

    -s    Source dnf repository address link (may be listed multiple times)

    -h    Show the help message and exit

##### isocut

isocut <font color=#0000FF >_[-h] [-t temporary path] [-r extern rpm path] [-k kickstart file path] origin-iso dest-iso_</font>

  Positional arguments:

    origin-iso    Origin ISO image
    dest-iso      Destination ISO image

  Optional arguments:

    -t    The temporary path, which must be an absolute path and must be greater than 8 GB

    -r    The external RPM package path

    -k    The kickstart file path

    -i    The isolinux cfg file path

    -g    The grub cfg file path

    -p    The anaconda pixmaps file path

    -h    Show the help message and exit

  isocut 详细文档请查看《镜像裁剪定制工具使用指南》：
  
    https://gitee.com/openeuler/docs/blob/9d89e4e41e7824f984ebc7a00b5f1241b84d1f85/docs/zh/docs/Isocut/%E9%95%9C%E5%83%8F%E8%A3%81%E5%89%AA%E5%AE%9A%E5%88%B6%E5%B7%A5%E5%85%B7%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97.md
