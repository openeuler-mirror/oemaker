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

#### Instructions

Generally, the disk space must be more than 50 GB.

#### Usage

##### oemaker

oemaker <font color=#0000FF >_[-h] [-t Type] [-p Product] [-v Version] [-r RELEASE] [-s REPOSITORY]_</font>

  Optional arguments:

    -t Type
       ISO type, including standard, debug, source, everything, everything_debug, everything_src, and netinst 

    -p Product
       Product name, for example, openEuler

    -v Version
       Version number

    -r RELEASE
       Release information

    -s REPOSITORY
       Source dnf repository address link (may be listed multiple times)

    -h 
       Show the help message and exit

##### isocut

isocut <font color=#0000FF >_[-h] [-t temporary path] [-r extern rpm path] [-k kickstart file path] origin-iso dest-iso_</font>

  Positional arguments:

    origin-iso    Origin ISO image
    dest-iso      Destination ISO image

  Optional arguments:

    -t    Temporary path, which must be an absolute path and must be greater than 8 GB
    -r    External RPM package path
    -k    Kickstart file path
    -h    Show the help message and exit