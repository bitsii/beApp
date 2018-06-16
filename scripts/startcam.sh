#!/bin/bash
export PATH=$PATH:.
if [ -e "./Data/KBridge/camEnabled.txt" ]; then
   (./App/IUCam/iuccmdrs.sh --appType server 2>&1 | split -b 10485760 - /tmp/capp$$.log) &
fi
