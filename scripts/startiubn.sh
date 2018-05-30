#!/bin/bash

cd $HOME

if [ -e "./apprun/Data/KBridge/dnsEnabled.txt" ]; then
   nohup ./apprun/App/KBridge/iubncmdrs.sh 2>&1 | split -b 10485760 - /tmp/iubn$$.dzlog & 
fi
