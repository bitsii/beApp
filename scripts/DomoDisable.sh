#!/bin/bash

rm -f Data/KBridge/domoEnabled.txt

killall -w -u $USER domoticz
kill `ps ax | grep domoticz | grep -v grep | awk '{$1=$1}1' | cut -d " " -f 1`

echo ""

