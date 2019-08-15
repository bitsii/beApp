#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

#mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkapp -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abelii/source/extended/LogSink.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/BrowserApWk.be ../abeliiApp/source/Db.be

#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#mkdir -p iosjs/resources/App/$APPBLDNM
#rm -f iosjs/resources/App/$APPBLDNM/BEX_E_app.js
#cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js iosjs/resources/App/$APPBLDNM/BEX_E_app.js

#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkui --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

mono --debug ../abelii/target5/BEX_E_mcs.exe -jsInclude=../abeliiApp/system/js/APWK_head.js ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkui --emitFlag apwk --ownProcess false --buildFile build/build.txt $BEBLDARGS --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abelii/source/extended/LogSink.be ../abeliiApp/source/BrowserEUI.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/BrowserApWk.be ../abeliiApp/source/Db.be



#--emitFlag ccIsIos

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js iosjs/resources/App/$APPBLDNM/BEX_E.js

cp -R resources/* iosjs/resources/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
