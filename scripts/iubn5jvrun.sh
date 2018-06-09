#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/KBridge/*" be.BEX_E --plugin KBridge:KBNamePlugin --appPlugin KBName --appType server --web.ssl false --web.port 6419 $*

#--appType browser 

cd ../ioturl
