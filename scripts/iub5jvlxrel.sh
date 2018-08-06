#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/KBridge

rm -rf ../apprun/App/KBridge
mkdir -p ../apprun/App/KBridge

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/KBridge/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/KBridge/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/KBridge/d --buildPath ../apprun/App/KBridge --emitLang jv --outputPlatform linux -mainClass=App:AppStart ../abelii/source/extended/Log.be source/IU.be source/IUHub.be source/KBridge.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abelii/system/jv/be/*.java ../apprun/App/KBridge/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/KBridge/d --buildPath ../apprun/App/KBridge --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUHub:Eui ../abelii/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

#for rel add 
# --outputPlatform linux 
#rm
# --emitFlag iuDebug 
# and change last line from run to rel

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/KBridge/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../edgii

cd ../abelii/system/jv
jar -cf ../../../apprun/App/KBridge/BEX_E_lib_jv.jar .
cd ../../../edgii

find ../abelii/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/KBridge/Base/target/js/be/BEX_E.js ../apprun/App/KBridge/IUHub_BEX_E.js
cp scripts/upgrade.bat ../apprun/App/KBridge
cp scripts/postupgrade.bat ../apprun/App/KBridge
cp scripts/setupbridge.sh ../apprun/App/KBridge
cp scripts/lilprepbridge.sh ../apprun/App/KBridge
cp scripts/userinstallbridge.sh ../apprun/App/KBridge
cp scripts/updateRouter.sh ../apprun/App/KBridge
cp scripts/prepbridge.sh ../apprun/App/KBridge
cp scripts/setupbridge2.sh ../apprun/App/KBridge
cp source/README_INSTALL.txt ../apprun/App/KBridge
cp scripts/installbridge.sh ../apprun/App/KBridge
cp scripts/changePiPass.sh ../apprun/App/KBridge
cp scripts/upgrade.sh ../apprun/App/KBridge
cp scripts/upgrade2.sh ../apprun/App/KBridge
cp scripts/postupgrade.sh ../apprun/App/KBridge
cp scripts/startiuh.sh ../apprun/App/KBridge
cp scripts/startball.sh ../apprun/App/KBridge
cp scripts/startcam.sh ../apprun/App/KBridge
cp scripts/starthass.sh ../apprun/App/KBridge
cp scripts/startdomo.sh ../apprun/App/KBridge
cp scripts/startbridge.sh ../apprun/App/KBridge
cp scripts/iuhcmdrs.sh ../apprun/App/KBridge
cp scripts/iuhcmd.sh ../apprun/App/KBridge
cp scripts/upgrade.bat ../apprun/App/KBridge
cp scripts/mpg123loop.sh ../apprun/App/KBridge
cp scripts/stopmpg123loop.sh ../apprun/App/KBridge
cp source/Konn.html ../apprun/App/KBridge
cp source/haproxy.cfg ../apprun/App/KBridge
cp scripts/starthap.sh ../apprun/App/KBridge
cp extlibs/KBridge/* ../apprun/App/KBridge
cp icons/* ../apprun/App/KBridge
cp licenses/* ../apprun/App/KBridge

#pure 
mkdir -p ../apprun/App/KBridge/css/layouts
rm -f ../apprun/App/KBridge/css/layouts/*
cp source/css/layouts/* ../apprun/App/KBridge/css/layouts

#cam
cp scripts/uppic.bat ../apprun/App/KBridge
cp scripts/uppic.sh ../apprun/App/KBridge
cp scripts/picUpload.sh ../apprun/App/KBridge
cp scripts/getcams.bat ../apprun/App/KBridge
cp scripts/getcams.sh ../apprun/App/KBridge
cp scripts/motionrun.sh ../apprun/App/KBridge
cp scripts/camclean.sh ../apprun/App/KBridge
cp source/MOCAM.conf ../apprun/App/KBridge

#apps
cp scripts/SSHEnable.sh ../apprun/App/KBridge
cp scripts/SSHDisable.sh ../apprun/App/KBridge
cp scripts/SBoxEnable.sh ../apprun/App/KBridge
cp scripts/SBoxDisable.sh ../apprun/App/KBridge
cp scripts/LEEnable.sh ../apprun/App/KBridge
cp scripts/LEDisable.sh ../apprun/App/KBridge
cp scripts/getLE.sh ../apprun/App/KBridge
cp scripts/lecf.sh ../apprun/App/KBridge
cp scripts/distcert.sh ../apprun/App/KBridge
cp scripts/ddclient ../apprun/App/KBridge
cp scripts/ddrun.sh ../apprun/App/KBridge
cp scripts/CamEnable.sh ../apprun/App/KBridge
cp scripts/CamDisable.sh ../apprun/App/KBridge
cp scripts/HassEnable.sh ../apprun/App/KBridge
cp scripts/HassDisable.sh ../apprun/App/KBridge
cp scripts/DomoEnable.sh ../apprun/App/KBridge
cp scripts/DomoDisable.sh ../apprun/App/KBridge
cp scripts/NxcEnable.sh ../apprun/App/KBridge
cp scripts/NxcDisable.sh ../apprun/App/KBridge
cp scripts/startnxc.sh ../apprun/App/KBridge
cp scripts/setupnxc.sh ../apprun/App/KBridge
cp source/nextcloud-enabled.conf ../apprun/App/KBridge
cp source/nextcloud-disabled.conf ../apprun/App/KBridge

#cd ../apprun
#./App/KBridge/iuhcmd.sh --appType server $*

./scripts/iubrel.sh
