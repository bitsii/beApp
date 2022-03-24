#!/bin/bash

#export APPBLDNM=${PWD##*/}

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --buildFile ../braceApp/build/extended.txt --deployPath njs --buildPath njs --emitLang js --ownProcess true ../brace/source/extended/Log.be $*

