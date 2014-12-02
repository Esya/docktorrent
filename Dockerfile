FROM debian:jessie

MAINTAINER kfei <kfei@kfei.net>

ENV VER_LIBTORRENT 0.13.4
ENV VER_RTORRENT 0.9.4
ENV VER_RUTORRENT 3.6

WORKDIR /usr/local/src

# This long disgusting instruction saves your image ~130 MB
RUN build_deps="automake build-essential libc-ares-dev libcppunit-dev libtool"; \
    build_deps="${build_deps} libssl-dev libxml2-dev libncurses5-dev pkg-config subversion wget"; \
    set -x && \
    apt-get update && apt-get install -q -y --no-install-recommends ${build_deps} && \
    wget http://curl.haxx.se/download/curl-7.39.0.tar.gz && \
    tar xzvfp curl-7.39.0.tar.gz && \
    cd curl-7.39.0 && \
    ./configure --enable-ares --enable-tls-srp --enable-gnu-tls --with-zlib --with-ssl && \
    make && \
    make install && \
    cd .. && \
    rm -rf curl-* && \
    ldconfig && \
    svn --trust-server-cert checkout https://svn.code.sf.net/p/xmlrpc-c/code/stable/ xmlrpc-c && \
    cd xmlrpc-c && \
    ./configure --enable-libxml2-backend --disable-abyss-server --disable-cgi-server && \
    make && \
    make install && \
    cd .. && \
    rm -rf xmlrpc-c && \
    ldconfig && \
    wget http://libtorrent.rakshasa.no/downloads/libtorrent-$VER_LIBTORRENT.tar.gz && \
    tar xzf libtorrent-$VER_LIBTORRENT.tar.gz && \
    cd libtorrent-$VER_LIBTORRENT && \
    ./autogen.sh && \
    ./configure --with-posix-fallocate && \
    make && \
    make install && \
    cd .. && \
    rm -rf libtorrent-* && \
    ldconfig && \
    wget http://libtorrent.rakshasa.no/downloads/rtorrent-$VER_RTORRENT.tar.gz && \
    tar xzf rtorrent-$VER_RTORRENT.tar.gz && \
    cd rtorrent-$VER_RTORRENT && \
    ./autogen.sh && \
    ./configure --with-xmlrpc-c --with-ncurses && \
    make && \
    make install && \
    cd .. && \
    rm -rf rtorrent-* && \
    ldconfig && \
    mkdir -p /usr/share/nginx/html && \
    cd /usr/share/nginx/html && \
    curl -L -O http://dl.bintray.com/novik65/generic/rutorrent-$VER_RUTORRENT.tar.gz && \
    curl -L -O http://dl.bintray.com/novik65/generic/plugins-$VER_RUTORRENT.tar.gz && \
    tar xzvpf rutorrent-$VER_RUTORRENT.tar.gz && \
    tar xzvpf plugins-$VER_RUTORRENT.tar.gz -C rutorrent/ && \
    rm -rf *.tar.gz && \
    apt-get purge -y --auto-remove ${build_deps} && \
    apt-get autoremove -y

# Install required packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    apache2-utils \
    nginx \
    php5-cli \
    php5-fpm

# Copy config files and a wrapper script
COPY config/nginx/default /etc/nginx/sites-available/default
COPY config/rtorrent/.rtorrent.rc /root/.rtorrent.rc
COPY config/rutorrent/config.php /usr/share/nginx/html/rutorrent/conf/config.php
COPY bin/docktorrent /usr/local/bin/docktorrent

# Install packages for ruTorrent plugins
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    libc-ares2 \
    mediainfo \
    unrar-free \
    unzip

# IMPORTANT: Change the default login/password of ruTorrent before build
RUN htpasswd -cb /usr/share/nginx/html/rutorrent/.htpasswd ducktorrent p@ssw0rd

EXPOSE 80 9527 45566

VOLUME ["/rtorrent", "/usr/share/nginx/html/rutorrent/share"]

WORKDIR /rtorrent

ENTRYPOINT ["/usr/local/bin/docktorrent"]