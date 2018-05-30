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
    export CLASSPATH="../abe-pl/target5/*;extlibs/KBridge/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/KBridge/*"
    ;;
esac

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/KBridge/d --buildPath ../apprun/App/KBridge --emitLang jv --outputPlatform linux -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHub.be source/KBridge.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/KBridge/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/KBridge/d --buildPath ../apprun/App/KBridge --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

#for rel add 
# --outputPlatform linux 
#rm
# --emitFlag iuDebug 
# and change last line from run to rel

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/KBridge/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/KBridge/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/KBridge/Base/target/js/be/BEX_E.js ../apprun/App/KBridge/IUHub_BEX_E.js
cp scripts/upgrade.bat ../apprun/App/KBridge
cp scripts/postupgrade.bat ../apprun/App/KBridge
cp scripts/inshared.sh ../apprun/App/KBridge
cp scripts/apinstall.sh ../apprun/App/KBridge
cp scripts/bridgeinstall.sh ../apprun/App/KBridge
cp scripts/upgrade.sh ../apprun/App/KBridge
cp scripts/upgrade2.sh ../apprun/App/KBridge
cp scripts/postupgrade.sh ../apprun/App/KBridge
cp scripts/startiuh.sh ../apprun/App/KBridge
cp scripts/startiubc.sh ../apprun/App/KBridge
cp scripts/startiuboh.sh ../apprun/App/KBridge
cp scripts/iuhrun.sh ../apprun/App/KBridge
cp scripts/iuhcmdrs.sh ../apprun/App/KBridge
cp scripts/iuhcmd.sh ../apprun/App/KBridge
cp scripts/upgrade.bat ../apprun/App/KBridge
cp scripts/mpg123loop.sh ../apprun/App/KBridge
cp scripts/stopmpg123loop.sh ../apprun/App/KBridge
cp source/Konn.html ../apprun/App/KBridge
cp extlibs/KBridge/* ../apprun/App/KBridge
cp icons/* ../apprun/App/KBridge
cp licenses/* ../apprun/App/KBridge

#oh
cp scripts/iupohcmdrs.sh ../apprun/App/KBridge
cp scripts/iupohcmd.sh ../apprun/App/KBridge
cp scripts/startoh.sh ../apprun/App/KBridge
cp scripts/startohinner.sh ../apprun/App/KBridge
cp scripts/startiupoh.sh ../apprun/App/KBridge

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
cp scripts/DnsEnable.sh ../apprun/App/KBridge
cp scripts/DnsDisable.sh ../apprun/App/KBridge
cp scripts/startiubn.sh ../apprun/App/KBridge
cp scripts/iubncmdrs.sh ../apprun/App/KBridge


#./scripts/iub5jvrun.sh $*

./scripts/iubrel.sh
