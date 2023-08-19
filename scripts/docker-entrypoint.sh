#!/bin/bash -e

#chown -R pixelfed:pixelfed .
#find . -type d -exec chmod 755 {} \; # set all directories to rwx by user/group
#find . -type f -exec chmod 644 {} \; # set all files to rw by user/group

if [ ! -f /opt/pixelfed/.env ]
then
    cd /opt/pixelfed
    cp /config.env .env

    php artisan key:generate
    php artisan storage:link
    php artisan migrate --force
    php artisan import:cities
    php artisan instance:actor
    php artisan passport:keys

    php artisan route:cache
    php artisan view:cache
    php artisan config:cache

    php artisan horizon:install
    php artisan horizon:publish
fi

# Run supervisor
supervisord -c /etc/supervisor/supervisord.conf

# execute a command given by CMD
# exec "$@"
