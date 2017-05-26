#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/IUHub

rm -rf ../apprun/App/IUHub
mkdir -p ../apprun/App/IUHub

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/IUBridge/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/IUBridge/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang jv --outputPlatform linux -mainClass=IUBridge:BridgeStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHubTest.be source/IUHub.be source/IUCam.be source/IUBridge.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUHub/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --ownProcess false --outputPlatform linux -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUHub/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/IUHub/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/IUHub/Base/target/js/be/BEX_E.js ../apprun/App/IUHub/IUHub_BEX_E.js
cp scripts/upgrade.bat ../apprun/App/IUHub
cp scripts/postupgrade.bat ../apprun/App/IUHub
cp scripts/upgrade.sh ../apprun/App/IUHub
cp scripts/upgrade2.sh ../apprun/App/IUHub
cp scripts/postupgrade.sh ../apprun/App/IUHub
cp scripts/startiuh.sh ../apprun/App/IUHub
cp scripts/iuhrun.sh ../apprun/App/IUHub
cp scripts/iuhcmdrs.sh ../apprun/App/IUHub
cp scripts/iuhcmd.sh ../apprun/App/IUHub
cp scripts/upgrade.bat ../apprun/App/IUHub
cp scripts/mpg123loop.sh ../apprun/App/IUHub
cp scripts/stopmpg123loop.sh ../apprun/App/IUHub
cp source/IU.html ../apprun/App/IUHub
cp extlibs/IUBridge/* ../apprun/App/IUHub
cp icons/* ../apprun/App/IUHub
cp licenses/* ../apprun/App/IUHub

#cam
cp scripts/uppic.bat ../apprun/App/IUHub
cp scripts/uppic.sh ../apprun/App/IUHub
cp scripts/getcams.bat ../apprun/App/IUHub
cp scripts/getcams.sh ../apprun/App/IUHub
cp scripts/motionrun.sh ../apprun/App/IUHub
cp scripts/camclean.sh ../apprun/App/IUHub
cp source/MOCAM.conf ../apprun/App/IUHub

#./scripts/iub5jvrun.sh $*

./scripts/iubrel.sh
