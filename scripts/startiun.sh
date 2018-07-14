#!/bin/bash
export PATH=$PATH:.
if [ -e "./Data/KBridge/camEnabled.txt" ]; then
   (./App/KBridge/iuncmdrs.sh --appType server 2>&1 | split -b 10485760 - /tmp/napp$$.log) &
fi
