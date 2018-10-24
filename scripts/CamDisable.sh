#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

rm -f Data/KBridge/camEnabled.txt

killall -w -u $USER iuccmdrs.sh
kill `ps ax | grep java | grep -v grep | grep CamPlugin | awk '{$1=$1}1' | cut -d " " -f 1`

rm -rf App/IUCam

echo ""

