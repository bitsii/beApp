#!/bin/bash

cd $HOME

if [ -e "./apprun/App/IUCam/startiuc.sh" ]; then
   nohup ./apprun/App/IUCam/startiuc.sh &
fi
