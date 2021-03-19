# oemaker

#### Description

The source package `oemaker` has two functions: iso making and iso cutting.Correspondingly, two software packages are generated: `oemaker` and `isocut`.

The generated binary rpm `oemaker` is a building tool for making DVD iso, include standard iso, debug iso, source iso, everything iso, everything source iso,everything debug iso and netinst iso.

The generated binary rpm `isocut` is a building tool for iso cutting which supports only RPM package-level.

#### Installation

To install `oemaker` and `isocut`, you can use `rpm` or `dnf` package manager command with openEuler repository.

Install `oemaker` with dnf
```sh
dnf install -y oemaker
```

Install `isocut` with dnf
```sh
dnf install -y isocut
```

#### Instructions

Generally, the disk space is more than 50g.

#### Usage

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
    -k    kickstart file path
    -h    show the help message and exit