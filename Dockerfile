# Drush Make will be depreciated in Drupal 9. All efforts MUST go into using Composer to bootstrap a site.
# Roadmap: https://github.com/drush-ops/drush/issues/2528
# They state they will support a tool to convert Makefiles into Composer files
# Make will keep getting bugfixes in Drush 8
# https://github.com/docker-library/php/blob/6844e717a56a5dd8ad87a236a96bea069cc635fd/5.6/alpine/Dockerfile
#####


# Alpine Linux is a security-orientated, lightweight Linux distribution based on musl-libc and busybox
# https://alpinelinux.org/
# https://www.musl-libc.org/
# https://busybox.net/about.html

FROM alpine:3.5

##
# Install software packaged by Alpine
##

RUN apk update  \
  && apk upgrade \
  && apk add \
    # terminal
    bash \
    # downloader
    curl \
    # version control
    git \
    # web server
    nginx \
    # security certificate handler
    ca-certificates \

##
# Install PHP extensions
##

    # Process Manager

    # FastCGI Process Manager - an alternative to the default PHP FastCGI with additional features
    # see https://php-fpm.org/
    php5-fpm \

    # File Manipulation

    # Zlib enables transparent read and write of gzip (.gz) compressed files.
    # see: http://php.net/manual/en/intro.zlib.php
    php5-zlib \

    # JavaScript Object Notation  was bundled and compiled into php core in  PHP 5.2.0 however the BusyBox default install
    # has it disabled by default.
    # The build error implied that php had originally been compiled with the --disable-json flag.
    php5-json \

    # XML: for definition . This extension parses but does not validate XML
    # see: https://www.w3.org/XML/
    php5-xml \

    # PHP Iconv interface. International text is mostly encoded in Unicode. For historical reasons
    # it is often still encoded using a language or country dependent character encoding.
    # http://www.gnu.org/software/libiconv/
    php5-iconv \

    # PHP Document Object Model - enables PHP to operate on XML documents through the DOM API
    php5-dom \

    # EXIF - enables extraction of information from EXIF photo information tags
    php5-exif \

    # GD - image tools
    # See: http://php.net/manual/en/intro.image.php
    php5-gd \


# Database Connectors

    # PHP Data Objects - interface for databases. See http://php.net/manual/en/intro.pdo.php
    php5-pdo \

    # PDO Mysql connector
    php5-pdo_mysql \

    # PDO Mysqli connector - allows you to access the functionality provided by MySQL 4.1 and above.
    php5-mysqli \

# encryption

    # generation and verification of signatures and for sealing (encrypting) and opening (decrypting) data. Provides a
    # subset of OpenSSL's features. See http://php.net/manual/en/intro.openssl.php
    php5-openssl

##
# Install musl
##

# Running apk add without the -u flag causes the php-fpm error:
# "Error relocating /usr/bin/php-fpm: __flt_rounds: symbol not found"
# TODO check if this bug has been fixed to allow musl to be moved into the section above - 13/5/17 still broken MRF
RUN apk add -u musl
  #####
  # WARNING: PHP Archive support will be dropped in drush 9 in favour of Composer
  #####
  # TODO remove this block once transitioned to Composer for Drush management
  # PHP Archive - enables PHP applications to be packaged into a single file '.phar'


RUN apk add  php5-phar
  #####
  # WARNING MCrypt is depreciated in PHP 7.1.0 and moved to PECL in 7.2.0
  #####
  #
  # Mcrypt Encryption Library
  # TODO change this when PHP 7 lands
  # we are obviously on PHP 5 in this project


RUN apk add  php5-mcrypt \
  && rm -rf /var/cache/apk/*

# copy files from the directory containing this into the Docker container
# ADD files/nginx.conf /etc/nginx/ #TODO
# ADD files/php-fpm.conf /etc/php/
# ADD files/run.sh /
# RUN chmod +x /run.sh

##
# Install Composer
##

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer \
    && chmod +x /usr/local/bin/composer

##
# Install Drupal
##

# TODO this is broken - hardcoding parameters below to bypass problem. Not a release blocker for a single site installation
# RUN composer create-project ${DRUPAL_SCAFFOLD}:${DRUPAL_VERSION} ${DRUPAL_ROOT} \
RUN composer create-project drupal-composer/drupal-project:8.x-dev /drupal \
  --stability dev \
  --profile \
  --no-interaction \
  --no-progress

##
# Install Drupal Contributed Modules
##

# Test proof-of-concept: Download Drupal contributed module

RUN cd /drupal \
  && composer require \
     drupal/icon:~1.0 \
     drupal/ctools:~3.0 \
     drupal/group:~1.0-beta5 \
     drupal/diff:~1.0-rc1 \
     drupal/fontawesome:~1.2 \
     drupal/pathauto:~1.0 \
     drupal/token:~1.0 \
     --prefer-dist \
     --no-progress \
     --prefer-stable \
     --no-update \
  && composer clear-cache

# TODO delete software not required outside of the build process e.g. curl composer ?openssl
# TODO uninstall php extensions not needed outside of the build process e.g. ?php5-phar
# TODO Licensing ?? MIT