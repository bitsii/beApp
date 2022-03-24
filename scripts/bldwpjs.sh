#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/App/$APPBLDNM

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt $BRBLDARGS --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js

if [ ! -z "$BEPOSTBUILD" -a "$BEPOSTBUILD" != " " ]; then
  eval "$BEPOSTBUILD"
fi
