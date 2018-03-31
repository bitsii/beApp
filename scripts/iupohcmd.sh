#!/bin/bash

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/KBridge/*" be.BEX_E --plugin App:WebReverseProxyPlugin --appPlugin WRProxy $*

