FROM tiredofit/nginx-php-fpm:7.0-latest
MAINTAINER Dave Conroy <dave at tiredofit dot ca>

### Default Runtime Environment Variables
  ENV OSTICKET_VERSION=1.10 \
      PHP_ENABLE_IMAP=TRUE

### Dependency Installation
  RUN apk update && \
      apk add \
          libmemcached-libs \
          msmtp \
          openldap \
          openssl \
          wget \
          zlib \
          && \

## Install Memcached Extenstion
  RUN BUILD_DEPS=" \
      autoconf \
      build-base \
      cyrus-sasl-dev \
      git \
      libmemcached-dev \
      php7-dev \
      php7-pear \
      sed \
      tar \
      zlib-dev" && \

      apk add ${BUILD_DEPS} && \
      cd /tmp && \
      git clone -b php7 https://github.com/php-memcached-dev/php-memcached && \
      cd php-memcached && \
      phpize7 && \ 
      ./configure --with-php-config=/usr/bin/php-config7 --disable-memcached-sasl && \
      make && \
      make install && \
      echo 'extension=memcached.so' >> /etc/php7/conf.d/20_memcached.ini && \
      apk del ${BUILD_DEPS} && \
      rm -rf /var/cache/apk/* /tmp/* && \

### Download & Prepare OSTicket for Install
    mkdir -p /assets/osticket && \
    cd /assets/osticket && \
    wget -nv -O osTicket.zip http://osticket.com/sites/default/files/download/osTicket-v${OSTICKET_VERSION}.zip && \
    unzip osTicket.zip && \
    rm osTicket.zip && \
    chown -R nginx:www-data /assets/osticket/upload/ && \
    chmod -R a+rX /assets/osticket/upload/ /assets/osticket/scripts/ && \
    chmod -R u+rw /assets/osticket/upload/ /assets/osticket/scripts/ && \
    mv /assets/osticket/upload/setup /assets/osticket/upload/setup_hidden && \
    chown -R root:root /assets/osticket/upload/setup_hidden && \
    chmod 700 /assets/osticket/upload/setup_hidden && \

# Download LDAP plugin
      wget -nv -O /assets/osticket/upload/include/plugins/auth-ldap.phar http://osticket.com/sites/default/files/download/plugin/auth-ldap.phar && \

### Log Miscellany Installation
   touch /var/log/msmtp.log && \
      chown nginx:www-data /var/log/msmtp.log

### Add Files
   ADD install /