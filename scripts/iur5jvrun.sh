#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/KRouter/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin KRouter:RouterPlugin --plugin App:ConfigPlugin --appPlugin KRouter --appType server $*

#--appType browser 

cd ../ioturl
