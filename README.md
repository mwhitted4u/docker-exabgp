# docker-exabgp

This is a fork of the excellent exabgp container created by Mike Nowak. Thanks Mike!

https://github.com/mikenowak/docker-exabgp

Modifications include...
 - Adjustments to the sample exabgp.conf file to support compatibility with Ubiquiti EdgeRouter devices
 - Inclusion of a script to check the health of an NS1 DDI DNS container

The container works with `NET_ADMIN` capabilities and `net=host` to automatically add loopback IP addresses to the host O/S.  The necessary routes for the created loopbacks are then advertised to neighbours.

# Prerequisites

 - This document assumes an existing NS1 DDI environment is deployed and operating normally.  All steps below should be performed on one or more of your edge hosts (i.e. the servers that host the `dns` containers)

 - Configuration of Anycast is very dependent on your network design and configuration.  Contact your network administrator(s) to assist.  You will at minimum need to know peer IP, remote AS, and local AS.  You will also need to know what IP to use for Anycast - it should _not_ exist on the host system.

 - Your DDI DNS container must have port 3300 (container configuration API) exposed as port 3301 on the host.  This should already be the case unless you've modified the default docker-compose files to remove this port mapping.

# Installation and Configuration

1) Download a copy of exabgp.conf.example and place it somewhere on the host system (i.e. /root/exabgp.conf).  Edit it and make the following adjustments:

 - Change neighbor IP, router-id, local-as, and peer-as as needed. Router ID is typically the primary IP address of the host system.  

 - If other configuration variables are necessary (multihop, authentication, etc), consult the exabgp documentation and add additional lines to the neighbor configuration section as needed.

 - Change the IP address after `--ip` in the `run` line under the watch-dns section.  This should be set to the Anycast IP address you wish to advertise.  This IP address will be automatically added as a loopback IP on the host system and will be advertised in BGP announcements.  T

 - If you have the DNS container's API port exposed as something other than port 3301, change the 3301 in the `run` line to the appropriate port.

 2) Add the following to the `services:` section of your `edge-compose.yml` file:

 ```
  anycast:
    image: mwhitted4u/exabgp:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
    restart: unless-stopped
    stop_grace_period: 30s
    network_mode: host
    cap_add:
      - NET_ADMIN
    volumes:
      - type: bind
        source: /root/exabgp.conf
        target: /usr/etc/exabgp/exabgp.conf
```

3) The anycast service can now be started in the same manner you would use to start the rest of the DDI services:

```docker-compose -p ddi -f edge-compose.yml up -d```

If you're using a different project name than `ddi`, change the value accordingly.

# Verification

Once the anycast service is running, use the following command to verify that healthchecks are passing and announcements are being sent:

```
$ docker logs ddi_anycast_1
...
16:55:03 | 15     | api             | route added to neighbor 10.4.100.1 local-ip None local-as 65042 peer-as 65001 router-id 10.4.100.3 family-allowed in-open : 10.4.1.10/32 next-hop self med 100
16:55:08 | 15     | api             | route added to neighbor 10.4.100.1 local-ip None local-as 65042 peer-as 65001 router-id 10.4.100.3 family-allowed in-open : 10.4.1.10/32 next-hop self med 100
...
```

Note that the logs indicate routes being added.  If you instead see logs showing routes being removed, the healthcheck is failing.  Confirm that the DNS container is running, the correct API port (usually 3301) is exposed, and that the DNS container is reporting `healthy`.

At this point, you should contact your network administrator to confirm that routes for the anycast IP are propagating properly.