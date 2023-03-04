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
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv --emitFlag jvad --emitFlag platDroid -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/BrowserJvAd.be ../beApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p android/$APPBLDNM/app/src/main/java/be
mkdir -p android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM
rm android/$APPBLDNM/app/src/main/java/be/BE*.java
cp ../beBase/system/jv/be/*.java android/$APPBLDNM/app/src/main/java/be
cp ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java android/$APPBLDNM/app/src/main/java/be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag jvad --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM/BEX_E.js

cp -R resources/* android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM

cp ../beApp/extlibs/jv/baad/* android/$APPBLDNM/app/libs

cd ../apprun/App/$APPBLDNM
