#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../beApp/scripts/runwacc.sh ../apprun/App/$APPBLDNM

una=`uname -a`

rm -rf ../apprun/App/$APPBLDNM/Base/target/cc ../apprun/App/$APPBLDNM/BEX_E_cl.exe

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cc --singleCC true --saveIds false --emitFlag ccSgc -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/WebServer.be ../beApp/source/WebApp.be ../beApp/source/Db.be ../beApp/source/MFSKvDb.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../beBase/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

time clang++ -DBEDCC_SGC=1 -pthread -o ../apprun/App/$APPBLDNM/BEX_E_cl.exe -ferror-limit=1 -std=c++14 ../apprun/App/$APPBLDNM/Base/target/cc/be/BEX_E.cpp -lsqlite3

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../beApp/extlibs/cc/wa/* ../apprun/App/$APPBLDNM
cp extlibs/cc/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
