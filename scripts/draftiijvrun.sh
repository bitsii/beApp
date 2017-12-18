#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/Draftii/*" be.BEX_E --plugin App:PublicReadPlugin --plugin Draftii:DraftiiPlugin --appPlugin Draftii --appType server $*

cd ../ioturl
