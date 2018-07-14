#!/bin/bash

rm -f Data/KBridge/dnsEnabled.txt

sudo apt -qq --assume-yes remove pdns-backend-remote pdns-server

killall -w -u $USER iuncmdrs.sh
kill `ps ax | grep java | grep -v grep | grep KBNamePlugin | awk '{$1=$1}1' | cut -d " " -f 1`

echo ""

