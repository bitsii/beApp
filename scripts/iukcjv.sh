#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/IUKC

rm -rf ../apprun/App/IUKC
mkdir -p ../apprun/App/IUKC

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/IUKC/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/IUKC/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUKC/d --buildPath ../apprun/App/IUKC --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/App.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUKC/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUKC/d --buildPath ../apprun/App/IUKC --emitLang js --ownProcess false -mainClass=IUKC:Eui ../abe-pl/source/extended/Log.be source/IUKCBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUKC/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/IUKC/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/IUKC/Base/target/js/be/BEX_E.js ../apprun/App/IUKC/IUKC_BEX_E.js
cp source/IU.html ../apprun/App/IUKC
cp extlibs/IUKC/* ../apprun/App/IUKC

cd ../apprun

export MYPWD=`pwd`

java -classpath "App/IUKC/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin IUCam:CamPlugin --plugin App:ConfigPlugin --appPlugin IUKC --appType browser $*

cd ../ioturl
