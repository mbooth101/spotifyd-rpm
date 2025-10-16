# Spotifyd RPMs

This repository contains specfiles for creating an RPM-installable version of [Spotifyd](https://github.com/Spotifyd/spotifyd).

The binary RPMs are hosted in a [COPR repository](https://copr.fedorainfracloud.org/coprs/mbooth/spotifyd/).

### Maintenance

Use the `rust2rpm` tool to create/update rust packages:

```
$ sudo dnf install rust2rpm
$ rust2rpm --store-crate --no-rpmautospec --ignore-missing-license-files <crate_name>@<version>
```
