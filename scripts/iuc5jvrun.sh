#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/IUCam/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUCam:CamPlugin --plugin App:ConfigPlugin --appPlugin IUCam --appType server $*

#--appType browser 

cd ../ioturl
