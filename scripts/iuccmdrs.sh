#!/bin/bash

killall motion

export MYPWD=`pwd`

export MYHN=`hostname`

while :; do
 java -classpath "App/IUCam/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUCam:CamPlugin --plugin App:ConfigPlugin --appName Cam --appPlugin IUCam --appType server $*
    echo "Exited code $?.  Will restart.." >&2
    killall motion
    sleep 1
done

