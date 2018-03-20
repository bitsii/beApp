#!/bin/bash

killall motion

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/KBridge/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin App:ConfigPlugin --appPlugin KBridge --appType server $*; do
    echo "Exited code $?.  Will restart.." >&2
    killall motion
    sleep 1
done

