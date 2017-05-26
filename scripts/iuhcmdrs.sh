#!/bin/bash

killall motion

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/IUHub/*" be.BEX_E $*; do
    echo "Exited code $?.  Will restart.." >&2
    killall motion
    sleep 1
done

