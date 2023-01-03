#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be -cchImport=../beApp/system/cc/be/BEH_AppPreImports.hpp --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cc --singleCC true --saveIds false --emitFlag ccSgc --emitFlag relocMain --emitFlag holdMain --emitFlag ccIsIos -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/BrowserCcIo.be ../beApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p ios/$APPBLDNM/$APPBLDNM
mkdir -p ios/resources/App/$APPBLDNM
rm -f ios/$APPBLDNM/$APPBLDNM/BE*.hpp
rm -f ios/$APPBLDNM/$APPBLDNM/BEX_E.mm
cp ../apprun/App/$APPBLDNM/Base/target/cc/be/BE*.hpp ios/$APPBLDNM/$APPBLDNM
cp ../apprun/App/$APPBLDNM/Base/target/cc/be/BEX_E.cpp ios/$APPBLDNM/$APPBLDNM/BEX_E.mm

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag ccIsIos --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ios/resources/App/$APPBLDNM/BEX_E.js

cp -R resources/* ios/resources/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
