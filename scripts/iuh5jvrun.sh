#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/IUHub/*" be.BEL_4_Base $*

cd ../ioturl
