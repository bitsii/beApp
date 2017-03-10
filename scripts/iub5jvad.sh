#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

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

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUHub/d --buildPath targetAd --emitFlag platDroid --emitLang jv -mainClass=IUBridge:BridgeStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHubTest.be source/IUHub.be source/IUCam.be source/IUBridge.be source/Db.be source/BrowserUI.be source/BrowserJvAd.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf android/IUHub/app/src/main/java/be
#mv targetAd/Base/target/jv/be android/IUHub/app/src/main/java/
#cp ../abe-pl/system/jv/be/*java android/IUHub/app/src/main/java/be

cp extlibs/IUBridge/* android/IUHub/app/libs/

exit 0

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUHub/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUHub/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/IUHub/BEL_4_Base_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/IUHub/Base/target/js/be/BEL_4_Base.js ../apprun/App/IUHub/IUHub_BEL_4_Base.js
cp scripts/upgrade.bat ../apprun/App/IUHub
cp scripts/postupgrade.bat ../apprun/App/IUHub
cp scripts/upgrade.sh ../apprun/App/IUHub
cp scripts/upgrade2.sh ../apprun/App/IUHub
cp scripts/postupgrade.sh ../apprun/App/IUHub
cp scripts/startiuh.sh ../apprun/App/IUHub
cp scripts/iuhrun.sh ../apprun/App/IUHub
cp scripts/iuhcmdrs.sh ../apprun/App/IUHub
cp scripts/iuhcmd.sh ../apprun/App/IUHub
cp scripts/createAdminAccount.sh ../apprun/App/IUHub
cp scripts/upgrade.bat ../apprun/App/IUHub
cp source/IU.html ../apprun/App/IUHub
cp extlibs/IUBridge/* ../apprun/App/IUHub
cp icons/* ../apprun/App/IUHub
cp extlibs/IUBridge/* ../apprun/App/IUHub
cp LICENSE.txt ../apprun/App/IUHub
cp LICENSE-MPL.txt ../apprun/App/IUHub

#cam
cp scripts/uppic.bat ../apprun/App/IUHub
cp scripts/uppic.sh ../apprun/App/IUHub
cp scripts/getcams.bat ../apprun/App/IUHub
cp scripts/getcams.sh ../apprun/App/IUHub
cp scripts/motionrun.sh ../apprun/App/IUHub
cp scripts/camclean.sh ../apprun/App/IUHub
cp source/MOCAM.conf ../apprun/App/IUHub
cp extlibs/IUCam/* ../apprun/App/IUHub

./scripts/iub5jvrun.sh $*
