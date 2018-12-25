#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/BC/*" be.BEX_E --plugin App:PublicReadPlugin --plugin BC:BCPlugin --appPlugin BC --appType server --app.ssl false --app.bindAddress 127.0.0.1 $*

#--appType browser 

cd ../edgiiSite
