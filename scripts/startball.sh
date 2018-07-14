#!/bin/bash
export PATH=$PATH:.:/sbin:/usr/sbin
./App/KBridge/startbridge.sh
sleep 5
./App/KBridge/startiun.sh
sleep 5
./App/KBridge/startcam.sh
sleep 5
./App/KBridge/startdomo.sh
sleep 5
./App/KBridge/startnxc.sh
