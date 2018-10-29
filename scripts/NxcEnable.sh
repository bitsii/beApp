#!/bin/bash

mkdir -p Data/KBridge/Apps
touch Data/KBridge/nxcEnabled.txt

#exit 0

if [ ! -e /var/www/html/nextcloud/index.php ]; then
  sudo ./App/KBridge/setupnxc.sh
fi

sudo rm -f /etc/apache2/sites-enabled/nextcloud.conf
sudo cp App/KBridge/nextcloud-enabled.conf /etc/apache2/sites-enabled/nextcloud.conf
sudo service apache2 restart

wget -t 20 --waitretry 1 --retry-connrefused http://127.0.0.1/nextcloud/
rm index.html

echo ""

