FROM alpine:3.7
MAINTAINER Matt Whitted <https://github.com/mwhitted4u>

RUN apk --no-cache add wget curl python python-dev py-setuptools coreutils netcat-openbsd bash \
    && apk --no-cache add --virtual build-dependencies build-base py-pip  \
    && mkdir -p /usr/etc/exabgp \
    && pip install ipaddr exabgp==4.0.5 ipy requests ntplib \
    && apk del build-dependencies 

ADD entrypoint.sh /
ADD exabgp.conf.example /usr/etc/exabgp/
ADD check_dns.py /usr/local/bin/
ADD check_ntp.py /usr/local/bin/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["exabgp"]
VOLUME ["/usr/etc/exabgp"]
EXPOSE 179
