#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base -jsInclude=../braceApp/system/js/APWK_head.js ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwkui --emitFlag apwk --ownProcess false --buildFile build/build.txt $BEBLDARGS --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/BrowserEUI.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/BrowserApWk.be ../braceApp/source/Db.be



#--emitFlag ccIsIos

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js > ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js.1
  lae=$?;if [[ $lae -eq 0 ]]; then
    rm -f ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js
    mv ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js.1 ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js
  fi
fi

mkdir -p iosjs/resources/App/$APPBLDNM
rm -f iosjs/resources/App/$APPBLDNM/BEX_E_app.js
cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js iosjs/resources/App/$APPBLDNM/BEX_E.js

cp -R resources/* iosjs/resources/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
