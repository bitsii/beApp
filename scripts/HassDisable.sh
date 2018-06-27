#!/bin/bash

rm -f Data/KBridge/hassEnabled.txt

killall -w -u $USER hass

pip3 uninstall -y homeassistant

echo ""

