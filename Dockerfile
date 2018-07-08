FROM alpine:3.7

EXPOSE 1883
EXPOSE 9883

VOLUME ["/var/lib/mosquitto", "/etc/mosquitto", "/etc/mosquitto.d"]

RUN addgroup -S mosquitto && \
    adduser -S -H -h /var/empty -s /sbin/nologin -D -G mosquitto mosquitto

ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH
ENV MOSQUITTO_VERSION=v1.4.11-opt

COPY run.sh /
COPY libressl.patch /
#RUN buildDeps='git build-base alpine-sdk openssl-dev libwebsockets-dev c-ares-dev util-linux-dev hiredis-dev curl-dev libxslt docbook-xsl'; \
RUN buildDeps='git build-base libressl-dev libwebsockets-dev c-ares-dev util-linux-dev hiredis-dev postgresql-dev curl-dev libxslt docbook-xsl'; \
    chmod +x /run.sh && \
    mkdir -p /var/lib/mosquitto && \
    touch /var/lib/mosquitto/.keep && \
    mkdir -p /etc/mosquitto.d && \
    echo "http://mirrors.aliyun.com/alpine/v3.7/main/" > /etc/apk/repositories && \
    apk update && \
    apk add $buildDeps hiredis postgresql-libs libwebsockets libuuid c-ares libressl curl ca-certificates && \
    #git clone https://github.com/eclipse/mosquitto.git && \
    git clone https://github.com/xdutaotao/mosquitto-1.4.11-opt.git mosquitto && \
    cd mosquitto && \
    #git checkout ${MOSQUITTO_VERSION} -b ${MOSQUITTO_VERSION} && \
    sed -i -e "s|(INSTALL) -s|(INSTALL)|g" -e 's|--strip-program=${CROSS_COMPILE}${STRIP}||' */Makefile */*/Makefile && \
    sed -i "s@/usr/share/xml/docbook/stylesheet/docbook-xsl/manpages/docbook.xsl@/usr/share/xml/docbook/xsl-stylesheets-1.79.1/manpages/docbook.xsl@" man/manpage.xsl && \
    sed -i 's/ -lanl//' config.mk && \
    patch -p1 < /libressl.patch && \
    #make WITH_MEMORY_TRACKING=no WITH_SRV=yes WITH_WEBSOCKETS=yes WITH_TLS_PSK=no && \
    make && \
    make install && \
    git clone git://github.com/jpmens/mosquitto-auth-plug.git && \
    cd mosquitto-auth-plug && \
    cp config.mk.in config.mk && \
    sed -i "s/BACKEND_REDIS ?= no/BACKEND_REDIS ?= yes/" config.mk && \
    sed -i "s/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/" config.mk && \
    sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk && \
    sed -i "s/BACKEND_POSTGRES ?= no/BACKEND_POSTGRES ?= yes/" config.mk && \
    sed -i "s/BACKEND_JWT ?= no/BACKEND_JWT ?= yes/" config.mk && \
    sed -i "s/MOSQUITTO_SRC =/MOSQUITTO_SRC = ..\//" config.mk && \
    sed -i "s/EVP_MD_CTX_new/EVP_MD_CTX_create/g" cache.c && \
    sed -i "s/EVP_MD_CTX_free/EVP_MD_CTX_destroy/g" cache.c && \
    make && \
    cp auth-plug.so /usr/local/lib/ && \
    cp np /usr/local/bin/ && chmod +x /usr/local/bin/np && \
    cd / && rm -rf mosquitto && rm /libressl.patch && \
    apk del $buildDeps && rm -rf /var/cache/apk/*

ADD mosquitto.conf /etc/mosquitto/mosquitto.conf

ENTRYPOINT ["/run.sh"]
CMD ["mosquitto"]
