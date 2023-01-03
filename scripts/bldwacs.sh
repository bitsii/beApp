#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../beApp/scripts/runwacs.sh ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwacs.bat ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cs --emitFlag cswa --emitFlag relocMain -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/WebServer.be ../beApp/source/WebApp.be ../beApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p cswa
rm cswa/BE*.cs
cp ../beBase/system/cs/be/*.cs cswa
cp ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs cswa

cd cswa
dotnet publish -o ../../apprun/App/$APPBLDNM
lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
cd ..

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
#cp ../beApp/extlibs/jv/ba/* ../apprun/App/$APPBLDNM
#cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
