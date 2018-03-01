#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/KRouter

rm -rf ../apprun/App/KRouter
mkdir -p ../apprun/App/KRouter

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/KRouter/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/KRouter/*"
    ;;
esac

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/KRouter/d --buildPath ../apprun/App/KRouter --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHub.be source/KRouter.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/KRouter/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/KRouter/d --buildPath ../apprun/App/KRouter --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/KRouter/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/KRouter/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/KRouter/Base/target/js/be/BEX_E.js ../apprun/App/KRouter/IUHub_BEX_E.js
cp scripts/upgrade.bat ../apprun/App/KRouter
cp scripts/postupgrade.bat ../apprun/App/KRouter
cp scripts/install.sh ../apprun/App/KRouter
cp scripts/interactiveInstall.sh ../apprun/App/KRouter
cp scripts/upgrade.sh ../apprun/App/KRouter
cp scripts/upgrade2.sh ../apprun/App/KRouter
cp scripts/postupgrade.sh ../apprun/App/KRouter
cp scripts/startiuh.sh ../apprun/App/KRouter
cp scripts/iuhrun.sh ../apprun/App/KRouter
cp scripts/iuhcmdrs.sh ../apprun/App/KRouter
cp scripts/iuhcmd.sh ../apprun/App/KRouter
cp scripts/upgrade.bat ../apprun/App/KRouter
cp scripts/mpg123loop.sh ../apprun/App/KRouter
cp scripts/stopmpg123loop.sh ../apprun/App/KRouter
cp source/Konn.html ../apprun/App/KRouter
cp source/IU.html ../apprun/App/KRouter
cp extlibs/KRouter/* ../apprun/App/KRouter
cp icons/* ../apprun/App/KRouter
cp licenses/* ../apprun/App/KRouter

#pure 
mkdir -p ../apprun/App/KRouter/css/layouts
rm -f ../apprun/App/KRouter/css/layouts/*
cp source/css/layouts/* ../apprun/App/KRouter/css/layouts

#cam
cp scripts/uppic.bat ../apprun/App/KRouter
cp scripts/uppic.sh ../apprun/App/KRouter
cp scripts/picUpload.sh ../apprun/App/KRouter
cp scripts/getcams.bat ../apprun/App/KRouter
cp scripts/getcams.sh ../apprun/App/KRouter
cp scripts/motionrun.sh ../apprun/App/KRouter
cp scripts/camclean.sh ../apprun/App/KRouter
cp source/MOCAM.conf ../apprun/App/KRouter

./scripts/iur5jvrun.sh $*
