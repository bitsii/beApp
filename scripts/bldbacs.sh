#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../braceApp/scripts/runwacs.sh ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cs --emitFlag cswa --emitFlag relocMain -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p cswa
rm cswa/BE*.cs
cp ../brace/system/cs/be/*.cs cswa
cp ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs cswa

cd cswa
dotnet publish -o ../../apprun/App/$APPBLDNM
lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
cd ..

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
#cp ../braceApp/extlibs/jv/ba/* ../apprun/App/$APPBLDNM
#cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
