#!/bin/bash

#export APPBLDNM=${PWD##*/}

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --buildFile ../beApp/build/extended.txt --deployPath njs --buildPath njs --emitLang js --ownProcess true ../beBase/source/extended/Log.be $*

