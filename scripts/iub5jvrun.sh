#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/KBridge/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin App:ConfigPlugin --appPlugin KBridge --appType server --app.ssl false --app.port 2018 --web.proto https --web.port 2019 --app.bindAddress 127.0.0.1 $*

#--appType browser 

cd ../ioturl
