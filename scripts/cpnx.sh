#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

if [ -e "/var/www/html/nextcloud/config/config.php" ];then

if [ "$1" == "get" ]; then
  rm -f ./config.php
  sudo cp /var/www/html/nextcloud/config/config.php ./config.php
  sudo chown $USER config.php
fi

if [ "$1" == "put" ]; then
  sudo cp -f ./config.php /var/www/html/nextcloud/config/config.php
  sudo chown www-data:www-data /var/www/html/nextcloud/config/config.php
  sudo service apache2 restart
fi

fi

