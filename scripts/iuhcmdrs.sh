#!/bin/bash

killall motion

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/IUHub/*" be.BEL_4_Base $*; do
    echo "Exited code $?.  Will restart.." >&2
    killall motion
    sleep 1
done

