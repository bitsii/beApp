#!/bin/bash

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

until java -classpath "App/Dz/*" be.BEL_4_Base.BEL_4_Base $*; do
    echo "Exited code $?.  Will restart.." >&2
    sleep 1
done

