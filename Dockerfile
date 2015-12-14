FROM php:5.6-apache

RUN a2enmod rewrite

# install the PHP extensions we need, and other packages
RUN apt-get update \
    && apt-get install -y
        libpng12-dev \
        libjpeg-dev \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

COPY /bin/docker-entrypoint.sh /entrypoint.sh

# copy the WordPress skeleton from this repo into the container
# this includes any themes and/or plugins we've added to the content/themes and content/plugins, etc, directories.
COPY /var/www/html /var/www/html

# install WordPress
ENV WORDPRESS_VERSION 4.3.1
ENV WORDPRESS_SHA1 b2e5652a6d2333cabe7b37459362a3e5b8b66221
# upstream tarballs include ./wordpress/ so this gives us /var/www/html/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
    && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
    && tar -xzf wordpress.tar.gz -C /var/www/html \
    && rm wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/html/wordpress

# install HyperDB, https://wordpress.org/plugins/hyperdb
ENV HYPERDB_TAG 1.1
RUN curl -Lo /var/www/html/hyperdb.zip https://downloads.wordpress.org/plugin/hyperdb.${HYPERDB_TAG}.zip \
    && unzip hyperdb.zip \
    && chown -R www-data:www-data /var/www/html/hyperdb \
    && mv hyperdb/db.php /var/www/html/wordpress/content/. \
    && rm -rf /var/www/html/hyperdb.zip /var/www/html/hyperdb

# install wp-cli, http://wp-cli.org
ENV WP_CLI_CONFIG_PATH /var/www/html/wp-cli.yml
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

# the volume is defined after we install everything
VOLUME /var/www/html

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
