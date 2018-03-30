#!/bin/bash

killall motion

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/IUCam/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUCam:CamPlugin --plugin App:ConfigPlugin --webPort 6416 --appPlugin IUCam --appType server $*; do
    echo "Exited code $?.  Will restart.." >&2
    killall motion
    sleep 1
done

