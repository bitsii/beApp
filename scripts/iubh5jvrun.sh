#!/bin/bash

cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -Djava.security.properties=App/IUHub/java.security -classpath "App/IUHub/*" be.BEL_4_Base $*

cd ../ioturl
