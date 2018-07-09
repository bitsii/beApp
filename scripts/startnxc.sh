#!/bin/bash
export PATH=$PATH:.
if [ -e "./Data/KBridge/nxcEnabled.txt" ]; then
   (./App/KBridge/starthap.sh Data/KBridge/Nxc.haproxy 2>&1 | split -b 10485760 - /tmp/nxchap$$.log) &
fi
