#!/bin/bash

#export APPBLDNM=${PWD##*/}

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --buildFile ../braceApp/build/extended.txt --deployPath njs --buildPath njs --emitLang js --ownProcess true ../brace/source/extended/Log.be $*

