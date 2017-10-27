#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/IUHub/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin IUCam:CamPlugin --plugin App:ConfigPlugin --appPlugin IUHub --appType browser --appType server $*

cd ../ioturl
