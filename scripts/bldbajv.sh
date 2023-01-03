#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../beApp/scripts/runbajv.sh ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/BrowserJvFx.be ../beApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../beBase/target5/*;extlibs/jv/*;../beApp/extlibs/jv/ba/*"
    ;;
  *)
    export CLASSPATH="../beBase/target5/*:extlibs/jv/*:../beApp/extlibs/jv/ba/*"
    ;;
esac

javac $BEJVARGS ../beBase/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/Base/target/jv
jar -cf ../../../BEX_E_app_jv.jar .
cd ../../../../../../$APPBLDNM

cd ../beBase/system/jv
jar -cf ../../../apprun/App/$APPBLDNM/BEX_E_lib_jv.jar .
cd ../../../$APPBLDNM

find ../beBase/system -name "*.class" -exec rm {} \;

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../beApp/extlibs/jv/ba/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
