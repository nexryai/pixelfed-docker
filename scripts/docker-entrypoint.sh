#!/bin/sh -e

#chown -R pixelfed:pixelfed .
#find . -type d -exec chmod 755 {} \; # set all directories to rwx by user/group
#find . -type f -exec chmod 644 {} \; # set all files to rw by user/group

if [ ! -f /opt/pixelfed/.env ]
then
    cd /opt/pixelfed
    cp /opts/pixelfed/config.env .env

    php artisan key:generate
    php artisan storage:link
    php artisan migrate --force
    php artisan import:cities

    set +e
    php artisan instance:actor
    php artisan passport:keys
    set -e

    php artisan route:cache
    php artisan view:cache
    php artisan config:cache

    php artisan horizon:install
    php artisan horizon:publish
fi

# Run supervisor
supervisord -c /etc/supervisord.conf

# execute a command given by CMD
# exec "$@"
