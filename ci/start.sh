#!/bin/sh

# Optional change of file ownerships
if [ -n "$CHOWN_TO_USER" ]; then chown -R $CHOWN_TO_USER /home/app; fi

# Clear the cache
rm -rf /home/app/storage/cache/*

# Run migrations
if [ -z "$APP_ENV" -o "$APP_ENV" != 'production' ]; then
  /usr/bin/php /home/app/artisan migrate
fi

# Import routes from services
/usr/bin/php /home/app/artisan gateway:parse

# Create key files
echo ${PRIVATE_KEY} > /home/app/storage/oauth-private.key
echo ${PUBLIC_KEY} > /home/app/storage/oauth-public.key

# Increase limits
upload_max_filesize=20M
post_max_size=20M
memory_limit=256M

for key in upload_max_filesize post_max_size memory_limit
do
 sed -i "s/^\($key\).*/\1 = $(eval echo \${$key})/" /etc/php/7.0/fpm/php.ini
done

# Start logging daemons if necessary
if [ -n ${LOGGING_LOGENTRIES} -a -n ${LOGGING_ID} ]; then 
  /root/logs-logentries.sh  
fi

# Install AppOptics if necessary
if [ -n ${APPOPTICS_SERVICE_KEY} ]; then
  /root/apm-appoptics.sh
fi

# Start up PHP FPM
/bin/echo clear_env = no >> /etc/php/7.0/fpm/pool.d/www.conf
/usr/sbin/php-fpm7.0
#this one doesn't expose env variables
#/usr/sbin/service php7.0-fpm start

/usr/sbin/nginx -g 'daemon off;'
