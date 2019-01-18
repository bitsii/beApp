#!/bin/bash

export USER=`whoami`

export PATH=$PATH:.
if [ -e "./Data/KBridge/domoEnabled.txt" ]; then
  while :; do
   killall -w -u $USER domoticz
   (cd ./Opt/Domo && ./domoticz -sslwww 0 -www 10010 2>&1 | split -b 10485760 - /tmp/domo$$.log)
     echo "Exited code $?.  Will restart.." >&2
     sleep 3
  done
fi
