#!/bin/bash
export PATH=$PATH:.
if [ -e "./Data/KBridge/domoEnabled.txt" ]; then
   (cd ./Opt/Domo && nohup ./domoticz -sslwww 0 -www 10010 2>&1 | split -b 10485760 - /tmp/domo$$.log) &
fi
