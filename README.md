# docker-exabgp

This is a fork of the excellent exabgp container created by Mike Nowak. Thanks Mike!

https://github.com/mikenowak/docker-exabgp

Modifications include...
 - Adjustments to the sample exabgp.conf file to support compatibility with Ubiquiti EdgeRouter devices
 - Inclusion of a script to check the health of an NS1 DDI DNS container

The container works with `NET_ADMIN` capabilities and `net=host` to add loopback interfaces to the
host OS (in my case CoreOS).

The routes are then advertised to neighbours.

Run as follows:

```
docker run -d --name exabgp --restart always \
           --cap-add=NET_ADMIN --net=host \
           -v exabgp:/usr/etc/exabgp mwhitted4u/exabgp
```
