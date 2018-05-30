#!/bin/bash

killall -w -u $USER iubncmdrs.sh
kill `ps ax | grep java | grep -v grep | grep KBNamePlugin | awk '{$1=$1}1' | cut -d " " -f 1`

mkdir -p Data/KBridge/Apps
touch Data/KBridge/dnsEnabled.txt

./App/KBridge/startiubn.sh

echo ""

