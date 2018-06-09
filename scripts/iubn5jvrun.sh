#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/KBridge/*" be.BEX_E --plugin KBridge:KBNamePlugin --appPlugin KBName --appType server --app.ssl false --app.port 6419 $*

#--appType browser 

cd ../ioturl
