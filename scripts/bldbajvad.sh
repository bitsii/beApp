#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../brace/target5/*;extlibs/jv/*;../braceApp/extlibs/jv/ba/*"
    ;;
  *)
    export CLASSPATH="../brace/target5/*:extlibs/jv/*:../braceApp/extlibs/jv/ba/*"
    ;;
esac

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv --emitFlag platDroid -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/BrowserJvAd.be ../braceApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p android/$APPBLDNM/app/src/main/java/be
mkdir -p android/$APPBLDNM/app/src/main/assets/App/BNote
rm android/$APPBLDNM/app/src/main/java/be/BE*.java
cp ../brace/system/jv/be/*.java android/$APPBLDNM/app/src/main/java/be
cp ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java android/$APPBLDNM/app/src/main/java/be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js android/$APPBLDNM/app/src/main/assets/App/BNote/BEX_E.js

cp -R resources/* android/$APPBLDNM/app/src/main/assets/App/BNote

cp ../braceApp/extlibs/jv/baad/* android/$APPBLDNM/app/libs

cd ../apprun/App/$APPBLDNM
