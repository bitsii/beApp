#!/bin/bash

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/KBridge/*" be.BEX_E --plugin KBridge:KBNamePlugin --appPlugin KBName --app.ssl false --app.port 6419 $*

