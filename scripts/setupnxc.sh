#!/bin/bash

cd /root

if [ ! -e /var/www/html/nextcloud ]; then
  rm -rf nextcloud
  
  curl https://download.nextcloud.com/server/releases/nextcloud-13.0.4.tar.bz2 |
 tar -jx

  if [ -e nextcloud/index.php ]; then
    #chown/chmod all the things
    cd nextcloud
    mkdir -p data
    chown www-data:www-data data config apps
    chmod 750 data
    cd ..
    mv nextcloud /var/www/html
  fi

fi

echo ""

