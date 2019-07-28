#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be -cchImport=../abeliiApp/system/cc/be/BEH_AppPreImports.hpp --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cc --singleCC true --saveIds false --emitFlag ccSgc --emitFlag relocMain --emitFlag holdMain --emitFlag ccIsIos -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abelii/source/extended/LogSink.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/BrowserCcIo.be ../abeliiApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p ios/$APPBLDNM/$APPBLDNM
mkdir -p ios/resources/App/BNote
rm -f ios/$APPBLDNM/$APPBLDNM/BE*.hpp
rm -f ios/$APPBLDNM/$APPBLDNM/BEX_E.mm
cp ../apprun/App/$APPBLDNM/Base/target/cc/be/BE*.hpp ios/$APPBLDNM/$APPBLDNM
cp ../apprun/App/$APPBLDNM/Base/target/cc/be/BEX_E.cpp ios/$APPBLDNM/$APPBLDNM/BEX_E.mm

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag ccIsIos --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ios/resources/App/BNote/BEX_E.js

cp -R resources/* ios/resources/App/BNote

cd ../apprun/App/$APPBLDNM
