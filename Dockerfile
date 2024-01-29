FROM php:8.2-fpm-alpine

WORKDIR /opt/pixelfed

RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.xtom.com.hk/alpine#g' /etc/apk/repositories \
    && apk add --no-cache ca-certificates autoconf alpine-sdk g++ build-base cmake clang icu libjpeg-turbo libpq libpng libwebp libzip icu-dev libjpeg-turbo-dev libpq-dev libpng-dev libwebp-dev libzip-dev supervisor nginx git \
    && addgroup -g 989 pixelfed \
    && adduser -u 989 -G pixelfed --disabled-password --no-create-home pixelfed \
    && git clone https://github.com/pixelfed/pixelfed . \
    && git checkout v0.11.9 \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install bcmath exif gd intl mysqli pcntl pdo_mysql pdo_pgsql zip \
    && pecl install redis && docker-php-ext-enable redis \
    && composer install --no-ansi --no-interaction --optimize-autoloader \
    && apk del autoconf alpine-sdk g++ build-base cmake clang git icu-dev libjpeg-turbo-dev libpq-dev libpng-dev libwebp-dev libzip-dev \
    && rm -rf .git

COPY ./configs/php.ini /usr/local/etc/php
COPY ./configs/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./configs/supervisord.conf /etc/supervisor
COPY ./configs/supervisor-fpm.conf ./configs/supervisor-horizon.conf ./configs/supervisor-cron.conf ./configs/supervisor-nginx.conf /etc/supervisor/conf.d
COPY ./configs/cron-pixelfed /var/spool/cron/crontabs/pixelfed
COPY ./configs/nginx.conf /etc/nginx/nginx.conf
COPY ./scripts/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh \
    && chown -R pixelfed:pixelfed . \
    && find . -type d -exec chmod 755 {} \; \
    && find . -type d -exec chmod 755 {} \;

CMD ["/docker-entrypoint.sh"]
