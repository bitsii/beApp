#!/bin/bash

cd apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/Dz/*" be.BEL_4_Base.BEL_4_Base $*

