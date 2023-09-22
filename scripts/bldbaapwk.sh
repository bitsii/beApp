#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

una=`uname -a`

if [ ! -z "$BERCME" -a "$BERCME" != " " ]; then
  if [ -e "$BERCME" ]; then
    . "$BERCME"
  fi
fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base -jsInclude=../beApp/system/js/APWK_head.js ../beBase/source/base/Uses.be $BRBLDARGS --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag apwk --ownProcess false --buildFile build/build.txt $BEBLDARGS --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/BrowserEUI.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/BrowserApWk.be ../beApp/source/Db.be $BEBLDARGS

#--emitFlag ccIsIos

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js

#if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
#then
#  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js > ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js.1
#  lae=$?;if [[ $lae -eq 0 ]]; then
#    rm -f ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js
#    mv ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js.1 ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js
#  fi
#fi

mkdir -p ios/$APPBLDNM/resources/App/$APPBLDNM
rm -f ios/$APPBLDNM/resources/App/$APPBLDNM/BEX_E_app.js
cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ios/$APPBLDNM/resources/App/$APPBLDNM/BEX_E.js

cp -R resources/* ios/$APPBLDNM/resources/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
