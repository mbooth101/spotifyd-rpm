# Spotifyd RPMs

An RPM packaged version of spotifyd, an open source Spotify client running as a UNIX daemon.

By default spotifyd behaves purely as a "Spotify Connect" device for official Spotify clients on the same network as the machine running the daemon.

## Installation Instructions

As root:

1. Install spotifyd:

```text
# dnf copr enable mbooth/spotifyd
# dnf install spotifyd
```

2. Enable the spotifyd service:

```text
# systemctl enable --now spotifyd.service
```

3. Open the Multicast DNS and Spotify Connect ports:

```text
# firewall-cmd --permanent --add-service=mdns
# firewall-cmd --permanent --add-service=spotify-connect
# systemctl reload firewalld
```

4. From an official Spotify client, spotifyd will be seen in the list of devices to which you may connect:

![Official Spotify Client Device Choice Menu](https://mbooth.fedorapeople.org/spotifyd.png)

5. For more advanced client functionality, see the `/etc/spotifyd.conf` file and [consult the upstream documentation](https://docs.spotifyd.rs/configuration/index.html) on how to configure the daemon.

## Reporting Bugs

For issues directly relating to the installation or RPM packaging of spotifyd, please file bugs at [github.com/mbooth101/spotifyd-rpm/issues](https://github.com/mbooth101/spotifyd-rpm/issues).

For defects in the spotifyd software itself, and only when you are 100% sure the problem is not a RPM packaging error, please file bugs at [github.com/Spotifyd/spotifyd/issues](https://github.com/Spotifyd/spotifyd/issues).

## Source and Binary Locations

This repository contains the source specfiles for creating the RPMs.

The binary RPMs are built and distributed by a [COPR repository](https://copr.fedorainfracloud.org/coprs/mbooth/spotifyd/).

