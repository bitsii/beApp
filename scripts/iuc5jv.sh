#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/IUCam

rm -rf ../apprun/App/IUCam
mkdir -p ../apprun/App/IUCam

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/IUCam/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/IUCam/*"
    ;;
esac

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUCam/d --buildPath ../apprun/App/IUCam --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/IUCam.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUCam/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUCam/d --buildPath ../apprun/App/IUCam --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUCam/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/IUCam/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/IUCam/Base/target/js/be/BEX_E.js ../apprun/App/IUCam/IUHub_BEX_E.js
cp source/IU.html ../apprun/App/IUCam
cp extlibs/IUCam/* ../apprun/App/IUCam
cp icons/* ../apprun/App/IUCam
cp licenses/* ../apprun/App/IUCam

#cam
cp scripts/uppic.bat ../apprun/App/IUCam
cp scripts/uppic.sh ../apprun/App/IUCam
cp scripts/picUpload.sh ../apprun/App/IUCam
cp scripts/getcams.bat ../apprun/App/IUCam
cp scripts/getcams.sh ../apprun/App/IUCam
cp scripts/motionrun.sh ../apprun/App/IUCam
cp scripts/camclean.sh ../apprun/App/IUCam
cp source/MOCAM.conf ../apprun/App/IUCam

./scripts/iuc5jvrun.sh $*
