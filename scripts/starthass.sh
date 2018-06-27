#!/bin/bash
export PATH=$PATH:.
if [ -e "./Data/KBridge/hassEnabled.txt" ]; then
   (hass 2>&1 | split -b 10485760 - /tmp/happ$$.log) &
fi
