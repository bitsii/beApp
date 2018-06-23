#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/KBridge

rm -rf ../apprun/App/KBridge
mkdir -p ../apprun/App/KBridge

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/KBridge/d --buildPath targetBr --emitLang cs --emitFlag iuDebug -mainClass=App:AppStart ../abelii/source/extended/Log.be source/IU.be source/IUHub.be source/KBridge.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp targetBr/Base/target/cs/be/*.cs cstargets/KBridgeCS/KBridgeCS

cp ../abelii/system/cs/be/*.cs cstargets/KBridgeCS/KBridgeCS

#mcs -debug:pdbonly -warn:0 -out:../apprun/App/KBridge/BEX_E_mcs.exe -warn:0 ../abelii/system/cs/be/*.cs ../apprun/App/KBridge/Base/target/cs/be/*.cs

#javac ../abelii/system/jv/be/*.java ../apprun/App/KBridge/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/KBridge/d --buildPath ../apprun/App/KBridge --emitLang js --emitFlag iuDebug --ownProcess false -mainClass=IUHub:Eui ../abelii/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

#for rel add 
#--outputPlatform linux 
#rm
#--emitFlag iuDebug 
# and change last line from run to rel

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#hub
cp ../apprun/App/KBridge/Base/target/js/be/BEX_E.js ../apprun/App/KBridge/IUHub_BEX_E.js
cp scripts/upgrade.bat ../apprun/App/KBridge
cp scripts/postupgrade.bat ../apprun/App/KBridge
cp scripts/bridgesetup.sh ../apprun/App/KBridge
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
cp extlibs/KBridgeCs/* ../apprun/App/KBridge
cp icons/* ../apprun/App/KBridge
cp licenses/* ../apprun/App/KBridge

#pure 
mkdir -p ../apprun/App/KBridge/css/layouts
rm -f ../apprun/App/KBridge/css/layouts/*
cp source/css/layouts/* ../apprun/App/KBridge/css/layouts
