#!/bin/bash

rm -f Data/KBridge/nxcEnabled.txt

sudo rm -f /etc/apache2/sites-enabled/nextcloud.conf
sudo cp App/KBridge/nextcloud-disabled.conf /etc/apache2/sites-enabled/nextcloud.conf
sudo service apache2 restart

echo ""

