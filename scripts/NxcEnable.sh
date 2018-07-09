#!/bin/bash

mkdir -p Data/KBridge/Apps
touch Data/KBridge/nxcEnabled.txt

if [ ! -e /var/www/html/nextcloud/index.php ]; then
  sudo ./App/KBridge/setupnxc.sh
fi

sudo rm -f /etc/apache2/sites-enabled/nextcloud.conf
sudo cp App/KBridge/nextcloud-enabled.conf /etc/apache2/sites-enabled/nextcloud.conf
sudo service apache2 restart

echo ""

