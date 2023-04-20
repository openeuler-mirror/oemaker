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

oemaker <font color=#0000FF >_[OPTION...]_</font>

  Common options:

    -c    Function select: isomaker or isocut
    -h    Show the help message and exit

  Make new ISO image selection options:

    -t    ISO type, including standard, debug, source, everything, everything_debug, everything_src, and netinst 

    -p    Product name, for example, openEuler

    -v    Version number

    -r    Release information

    -s    Source dnf repository address link (may be listed multiple times)

  Customize the ISO selection options:

    -t    The temporary path, which must be an absolute path and must be greater than 8 GB

    -r    The external RPM package path

    -k    The kickstart file path

    -i    The isolinux cfg file path

    -g    The grub cfg file path

    -p    The anaconda pixmaps file path
