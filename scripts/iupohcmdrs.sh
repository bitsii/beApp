#!/bin/bash

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/KBridge/*" be.BEX_E  --plugin App:WebReverseProxyPlugin --appPlugin WRProxy --appType server --webPort 6415 --proxyDestUrl http://127.0.0.1:8080 $*; do
    echo "Exited code $?.  Will restart.." >&2
    sleep 1
done

