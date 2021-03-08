#!/bin/bash

#export APPBLDNM=${PWD##*/}

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --buildFile ../abeliiApp/build/extended.txt --deployPath njs --buildPath njs --emitLang js --ownProcess true ../abelii/source/extended/Log.be $*

