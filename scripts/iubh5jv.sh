#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/IUHub
mkdir -p ../apprun/App/IUHub

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/IUHub/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/IUHub/*"
    ;;
esac

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang jv -mainClass=IUHub:BigHubStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHubTest.be source/IUHub.be source/IUCam.be source/IUBigHub.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUHub/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUCam/d --buildPath ../apprun/App/IUCam --emitLang js --ownProcess false -mainClass=IUCam:Eui ../abe-pl/source/extended/Log.be source/IUCamBr.be source/BrowserEUI.be

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
cp scripts/startiuhlw.sh ../apprun/App/IUHub
cp scripts/iuhrun.sh ../apprun/App/IUHub
cp scripts/iuhcmdrs.sh ../apprun/App/IUHub
cp scripts/iuhcmd.sh ../apprun/App/IUHub
cp scripts/upgrade.bat ../apprun/App/IUHub
cp source/IUHub*.html ../apprun/App/IUHub
cp extlibs/IUHub/* ../apprun/App/IUHub
cp icons/* ../apprun/App/IUHub
cp LICENSE.txt ../apprun/App/IUHub
cp LICENSE-MPL.txt ../apprun/App/IUHub

#cam
cp ../apprun/App/IUCam/Base/target/js/be/BEL_4_Base.js ../apprun/App/IUHub/IUCam_BEL_4_Base.js
cp scripts/uppic.bat ../apprun/App/IUHub
cp scripts/uppic.sh ../apprun/App/IUHub
cp scripts/getcams.bat ../apprun/App/IUHub
cp scripts/getcams.sh ../apprun/App/IUHub
cp scripts/motionrun.sh ../apprun/App/IUHub
cp scripts/camclean.sh ../apprun/App/IUHub
cp source/IUCam*.html ../apprun/App/IUHub
cp source/MOCAM.conf ../apprun/App/IUHub

./scripts/iubh5jvrun.sh $*
