#!/bin/bash

rm -f Data/KBridge/dnsEnabled.txt

killall -w -u $USER iuccmdrs.sh
kill `ps ax | grep java | grep -v grep | grep CamPlugin | awk '{$1=$1}1' | cut -d " " -f 1`

echo ""

