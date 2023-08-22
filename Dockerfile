FROM php:8.2-fpm

WORKDIR /opt/pixelfed

RUN useradd -rU -s /bin/bash pixelfed

RUN apt-get update \
    && apt-get -y install cron libicu-dev libjpeg62-turbo-dev libpq-dev libpng-dev libwebp-dev libzip-dev supervisor nginx git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/pixelfed/pixelfed . \
    && git checkout v0.11.9 \
    && apt-get -y purge git

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer

RUN docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install bcmath exif gd intl mysqli pcntl pdo_mysql pdo_pgsql zip \
    && pecl install redis && docker-php-ext-enable redis

RUN composer install --no-ansi --no-interaction --optimize-autoloader

COPY ./configs/php.ini /usr/local/etc/php
COPY ./configs/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./configs/supervisord.conf /etc/supervisor
COPY ./configs/supervisor-fpm.conf ./configs/supervisor-horizon.conf ./configs/supervisor-cron.conf ./configs/supervisor-nginx.conf /etc/supervisor/conf.d
COPY ./configs/cron-pixelfed /etc/cron.d/pixelfed
COPY ./configs/nginx.conf /etc/nginx/nginx.conf

COPY ./scripts/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh \
    && chown -R pixelfed:pixelfed . \
    && find . -type d -exec chmod 755 {} \; \
    && find . -type d -exec chmod 755 {} \;

CMD ["/docker-entrypoint.sh"]
