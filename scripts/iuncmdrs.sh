#!/bin/bash

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/KBridge/*" be.BEX_E --plugin KBridge:KBNamePlugin --appPlugin KBName --appType server --app.ssl false --app.port 6419 $*; do
    echo "Exited code $?.  Will restart.." >&2
    sleep 1
done
