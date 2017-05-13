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
# Configure Environment
# TODO set these Environment variables from one central .env file.
# Not an beta release blocker when we are talking about 1 production site and one development machine
# beta means its feature complete and by the time the image is building all of the modules
##

# Set Drupal Scaffolding provider
ENV DRUPAL_SCAFFOLD: drupal-composer/drupal-project

# Set Drupal version
ENV DRUPAL_VERSION: 8.x-dev

# Set Stability Level
#
# I.E. do not allow composer modules below a certain stability level to be downloaded. This
# applies to Drupal modules as well.
#
# Options are:
#   - dev : allows all development versions
#   - alpha : modules may not be not feature complete or backwards compatable
#   - beta : modules are usually feature complete but API-breaking changes are still allowed
#   - RC: modules are always feature complete but API-breaking changes may rarely still happen
#   - stable : only the latest stable full releases are allowed to be installed

# ENV STABILITY_LEVEL: beta

# Set Composer Version
ENV COMPOSER_VERSION 1.4.1

# Set where Drupal Core will be installed
# TODO This may already be set by Drupal: check this doesn't cause errors.
# TODO May not need ""s
ENV DRUPAL_ROOT: testbuild

##
# Install BusyBox software packaged by Alpine
##

RUN apk update  \
  && apk upgrade \
  && apk add \
    # terminal
    bash \
    # downloader
    curl
    # version control
RUN apk add git \
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

  #####
  # WARNING: PHP Archive support will be dropped in drush 9 in favour of Composer
  #####
  # TODO remove this block once transitioned to Composer for Drush management
  # PHP Archive - enables PHP applications to be packaged into a single file '.phar'
  php5-phar

# Database Connectors

  # PHP Data Objects - interface for databases. See http://php.net/manual/en/intro.pdo.php
RUN apk add  php5-pdo \

  # PDO Mysql connector
  php5-pdo_mysql \

  # PDO Mysqli connector - allows you to access the functionality provided by MySQL 4.1 and above.
  php5-mysqli

# encryption

  # generation and verification of signatures and for sealing (encrypting) and opening (decrypting) data. Provides a
  # subset of OpenSSL's features. See http://php.net/manual/en/intro.openssl.php
RUN apk add php5-openssl \

  #####
  # WARNING MCrypt is depreciated in PHP 7.1.0 and moved to PECL in 7.2.0
  #####
  #
  # Mcrypt Encryption Library
  # TODO change this when PHP 7 lands
  # we are obviously on PHP 5 in this project
  php5-mcrypt

##
# Install musl
##

# musl is the C library for Alpine Linux. It is cleaner, faster & much smaller than glibc.
# Running apk add without the -u flag causes the php-fpm error:
# "Error relocating /usr/bin/php-fpm: __flt_rounds: symbol not found"
# TODO check if this bug has been fixed to allow musl to be moved into the section above - 13/5/17 still broken MRF
RUN apk add -u musl

# cleanup apk software package cache to minimise image size
RUN rm -rf /var/cache/apk/*

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
#    --version=${COMPOSER_VERSION} \ # TODO
    && chmod +x /usr/local/bin/composer

##
# Install Drupal
##

# The drupal-composer project ( https://github.com/drupal-composer/drupal-project ) provides all of the composer
# dependencies and scaffolding files for drupal leaving us with only the drupal contributed modules to deal with in the
# composer.json file. Nice and clean.
#
# composer create-project flags:
# --stability dev     latest package versions. Presumably should be changed in production and needs abstracting
# --no-dev            do not load development software stack. Presumably needs removing in development environment
# --profile           display timing and memory usage information
# --no-interaction    needs to be preset to stop installer askingAL_is case the --keep-vcs flag should be uncommented below.
# --no-progress       disable download progress display as it clutters the terminal

# example from DO
# composer create-project drupal-composer/drupal-project:8.x-dev some-dir --stability dev --no-interaction
# TODO this is broken - hardcoding parameters below. Not a release blocker for a single site installation
# RUN composer create-project ${DRUPAL_SCAFFOLD}:${DRUPAL_VERSION} ${DRUPAL_ROOT} \
RUN composer create-project drupal-composer/drupal-project:8.x-dev some-dir \
  --stability dev \
  --no-dev \
  --profile \
  --no-interaction \
  --no-progress

# TODO install drupal modules

# TODO cleanup composer installation files for this image layer
# TODO delete software not required outside of the build process e.g. curl composer ?openssl
# TODO uninstall php extensions not needed outside of the build process e.g. ?php5-phar
# TODO Licensing ?? MIT