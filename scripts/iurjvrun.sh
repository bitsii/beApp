#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/Iur/*" be.BEX_E $*

cd ../ioturl
