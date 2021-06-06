#!/bin/bash

rm -rf targetAppTestwabr

time mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be -deployPath=deployAppTestwabr -buildPath=targetAppTestwabr -libraryName=AppTest -mainClass=AppTestbr:Tests -loadSyns=lib/wabr/js/BEL_App.syn -initLib=App -jsInclude=lib/wabr/js/BEL_App.js --emitLang js source/AppTestbr.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

node targetAppTestwabr/AppTest/target/js/be/BEL_AppTest.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
