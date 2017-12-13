#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/SLIHold/*" be.BEX_E --plugin App:PublicReadPlugin --plugin SLIHold:SLIHoldPlugin --appPlugin SLIHold --appType server $*

cd ../ioturl
