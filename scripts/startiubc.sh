#!/bin/bash

cd /home/pi

if [ -e "./apprun/App/IUCam/startiuc.sh" ]; then
   nohup ./apprun/App/IUCam/startiuc.sh &
fi
