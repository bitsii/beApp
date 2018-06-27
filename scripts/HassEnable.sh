#!/bin/bash

rm -f Data/KBridge/hassEnabled.txt

killall -w -u $USER hass

mkdir -p Data/KBridge/Apps
touch Data/KBridge/hassEnabled.txt

pip3 uninstall -y homeassistant

pip3 install --user "homeassistant<0.60"
#pip3 install --user homeassistant

hass &
sleep 10
killall -w -u $USER hass
hass &
sleep 15
killall -w -u $USER hass
hass &

echo ""

