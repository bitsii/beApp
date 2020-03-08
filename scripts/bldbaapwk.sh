#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

#mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkapp -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/BrowserApWk.be ../braceApp/source/Db.be

#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi


#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkui --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

mono --debug ../brace/target5/BEX_E_mcs.exe -jsInclude=../braceApp/system/js/APWK_head.js ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkui --emitFlag apwk --ownProcess false --buildFile build/build.txt $BEBLDARGS --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/BrowserEUI.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/BrowserApWk.be ../braceApp/source/Db.be



#--emitFlag ccIsIos

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p iosjs/resources/App/$APPBLDNM
rm -f iosjs/resources/App/$APPBLDNM/BEX_E_app.js
cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js iosjs/resources/App/$APPBLDNM/BEX_E.js

cp -R resources/* iosjs/resources/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
