ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-fpm-alpine

WORKDIR /var/www

RUN apk update && apk add \
    curl \
    nginx \
    supervisor

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions pcntl intl pdo_pgsql

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY deploy/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY deploy/app.conf /etc/nginx/nginx.conf
COPY deploy/supervisor.conf /etc/supervisord.conf

COPY . /var/www

RUN mkdir -p vendor

RUN mkdir -p var/cache var/log var/sessions

RUN chown -R www-data:www-data var

COPY --from=composer /usr/bin/composer /usr/bin/composer

ENV APP_ENV=dev

#RUN composer install --no-cache --prefer-dist --no-progress
#--no-dev
#--no-scripts
#--no-autoloader 

#RUN set -eux; \
#    composer dump-autoload --classmap-authoritative; \
#    composer dump-env dev; \
#    composer run-script post-install-cmd; \
#    chmod +x bin/console; sync;
RUN composer install

RUN bin/console cache:clear --env=prod
RUN bin/console asset-map:compile --env=prod

RUN ["chmod", "+x", "/var/www/entrypoint.sh"]
ENTRYPOINT [ "/var/www/entrypoint.sh" ]
