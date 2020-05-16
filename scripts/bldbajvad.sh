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
    export CLASSPATH="../abelii/target5/*;extlibs/jv/*;../abeliiApp/extlibs/jv/ba/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/jv/*:../abeliiApp/extlibs/jv/ba/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv --emitFlag platDroid -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abelii/source/extended/LogSink.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/BrowserJvAd.be ../abeliiApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p android/$APPBLDNM/app/src/main/java/be
mkdir -p android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM
rm android/$APPBLDNM/app/src/main/java/be/BE*.java
cp ../abelii/system/jv/be/*.java android/$APPBLDNM/app/src/main/java/be
cp ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java android/$APPBLDNM/app/src/main/java/be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM/BEX_E.js

cp -R resources/* android/$APPBLDNM/app/src/main/assets/App/$APPBLDNM

cp ../abeliiApp/extlibs/jv/baad/* android/$APPBLDNM/app/libs

cd ../apprun/App/$APPBLDNM
