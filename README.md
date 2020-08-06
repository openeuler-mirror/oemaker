# oemaker

#### Description

`oemaker` is a building tool for making DVD iso, include standard iso, debug iso and source iso.
`oemaker` uses local arch when building, did not support cross building.
currently, `oemaker` support the arch of aarch64 and x86_64 for iso making.

#### Installation

To install `oemaker`, you can use `rpm` or `dnf` package manager command with openEuler repository.

Install oemaker with dnf
```sh
dnf install -y oemaker
```

#### Instructions

Generally, the disk space is more than 50g.

#### Contribution

oemaker <font color=#0000FF >_[-t Type] [-p Product] [-v Version] [-r RELEASE] [-s REPOSITORY]_</font>

    optional arguments:
    -t Type
       ISO Type include standard debug and source

    -p Product
       Product Name, such as: openEuler

    -v Version
       version identifier

    -r RELEASE
       release information

    -s REPOSITORY
       source dnf repository address link(may be listed multiple times)
