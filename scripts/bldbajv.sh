#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../braceApp/scripts/runbajv.sh ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/BrowserJvFx.be ../braceApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../brace/target5/*;extlibs/jv/*;../braceApp/extlibs/jv/ba/*"
    ;;
  *)
    export CLASSPATH="../brace/target5/*:extlibs/jv/*:../braceApp/extlibs/jv/ba/*"
    ;;
esac

javac $BEJVARGS ../brace/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/Base/target/jv
jar -cf ../../../BEX_E_app_jv.jar .
cd ../../../../../../$APPBLDNM

cd ../brace/system/jv
jar -cf ../../../apprun/App/$APPBLDNM/BEX_E_lib_jv.jar .
cd ../../../$APPBLDNM

find ../brace/system -name "*.class" -exec rm {} \;

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../braceApp/extlibs/jv/ba/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
