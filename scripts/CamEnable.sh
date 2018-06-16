#!/bin/bash

killall -w -u $USER iuccmdrs.sh
kill `ps ax | grep java | grep -v grep | grep CamPlugin | awk '{$1=$1}1' | cut -d " " -f 1`

mkdir -p Data/KBridge/Apps
touch Data/KBridge/camEnabled.txt

(./App/IUCam/iuccmdrs.sh --appType server 2>&1 | split -b 10485760 - /tmp/capp$$.log) &

echo ""

