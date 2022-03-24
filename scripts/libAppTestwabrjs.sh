#!/bin/bash

rm -rf targetAppTestwabr

export CLASSPATH=../brace/target5/*
time java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be -deployPath=deployAppTestwabr -buildPath=targetAppTestwabr -libraryName=AppTest -mainClass=AppTestbr:Tests -loadSyns=lib/wabr/js/BEL_App.syn -initLib=App -jsInclude=lib/wabr/js/BEL_App.js --emitLang js source/AppTestbr.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

node targetAppTestwabr/AppTest/target/js/be/BEL_AppTest.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
