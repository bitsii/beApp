#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/WRProxy/*" be.BEX_E --plugin App:WebReverseProxyPlugin  --appPlugin WRProxy --appType server $*

#--appType browser 

cd ../ioturl
