#!/bin/bash

mkdir -p csaweb/csaweb
mkdir -p csaweb/csaweb/App
mkdir -p csaweb/csaweb/Data
mkdir -p csaweb/csaweb/Data/IUHub

rm -rf csaweb/csaweb/App/IUHub
mkdir -p csaweb/csaweb/App/IUHub

rm -rf targetMc
mkdir -p targetMc

mono --debug ../abe-pl/target5/BEL_4_Base_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath targetMc/d --buildPath targetMc --emitFlag iuDebug --emitLang cs -mainClass=IUHub:HubWebStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHub.be source/IUHubWebStart.be source/Db.be source/SlDb.be source/BrowserUI.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm csaweb/csaweb/BEC*.cs
cp targetMc/Base/target/cs/be/*.cs csaweb/csaweb
cp ../abe-pl/system/cs/be/*.cs csaweb/csaweb
cp system/cs/*.cs csaweb/csaweb

xbuild csaweb/csaweb/csaweb.csproj

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#cp csaweb/csaweb/Web.config csaweb/csaweb
#cp csaweb/csaweb/bin/* csaweb/csaweb/App/IUHub/

mono --debug ../abe-pl/target5/BEL_4_Base_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath csaweb/csaweb/App/IUHub/d --buildPath csaweb/csaweb/App/IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#hub
cp csaweb/csaweb/App/IUHub/Base/target/js/be/BEL_4_Base.js csaweb/csaweb/App/IUHub/IUHub_BEL_4_Base.js
cp scripts/upgrade.bat csaweb/csaweb/App/IUHub
cp scripts/postupgrade.bat csaweb/csaweb/App/IUHub
cp scripts/upgrade.sh csaweb/csaweb/App/IUHub
cp scripts/upgrade2.sh csaweb/csaweb/App/IUHub
cp scripts/postupgrade.sh csaweb/csaweb/App/IUHub
cp scripts/startiuh.sh csaweb/csaweb/App/IUHub
cp scripts/iuhrun.sh csaweb/csaweb/App/IUHub
cp scripts/iuhcmdrs.sh csaweb/csaweb/App/IUHub
cp scripts/iuhcmd.sh csaweb/csaweb/App/IUHub
cp scripts/upgrade.bat csaweb/csaweb/App/IUHub
cp scripts/mpg123loop.sh csaweb/csaweb/App/IUHub
cp scripts/stopmpg123loop.sh csaweb/csaweb/App/IUHub
cp source/IU.html csaweb/csaweb/App/IUHub
cp extlibs/IUHub/* csaweb/csaweb/App/IUHub
cp icons/* csaweb/csaweb/App/IUHub
cp licenses/* csaweb/csaweb/App/IUHub

#cam
cp scripts/uppic.bat csaweb/csaweb/App/IUHub
cp scripts/uppic.sh csaweb/csaweb/App/IUHub
cp scripts/getcams.bat csaweb/csaweb/App/IUHub
cp scripts/getcams.sh csaweb/csaweb/App/IUHub
cp scripts/motionrun.sh csaweb/csaweb/App/IUHub
cp scripts/camclean.sh csaweb/csaweb/App/IUHub
cp source/MOCAM.conf csaweb/csaweb/App/IUHub

cp extlibs/IUHubCs/* csaweb/csaweb/App/IUHub

./scripts/pingws.sh &

cd csaweb/csaweb
PATH=$PATH:./App/IUHub

xsp
