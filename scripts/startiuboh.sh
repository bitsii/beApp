#!/bin/bash

cd /home/pi

if [ -e "./openhab/start.sh" ]; then
   screen -dmS test bash -c '/home/pi/openhab/start.sh 2>/tmp/oherr >/tmp/ohout'
   ./apprun/App/KBridge/startiupoh.sh
fi
