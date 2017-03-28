#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/IUHub
mkdir -p ../apprun/App/IUHub

rm -rf targetMc
mkdir -p targetMc

mono --debug ../abe-pl/target5/BEL_4_Base_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath targetMc/d --buildPath targetMc --emitLang cs -mainClass=IUHub:HubWebStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHub.be source/IUHubWebStart.be source/Db.be source/BrowserUI.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf csweb/IUHubWeb/IUHubWeb/be
mv targetMc/Base/target/cs/be csweb/IUHubWeb/IUHubWeb/be/
cp ../abe-pl/system/cs/be/*.cs csweb/IUHubWeb/IUHubWeb/be/

xbuild csweb/IUHubWeb/IUHubWeb/IUHubWeb.csproj

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp csweb/IUHubWeb/IUHubWeb/bin/Debug/* ../apprun/App/IUHub/

mono --debug ../abe-pl/target5/BEL_4_Base_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

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
cp scripts/upgrade.bat ../apprun/App/IUHub
cp scripts/mpg123loop.sh ../apprun/App/IUHub
cp scripts/stopmpg123loop.sh ../apprun/App/IUHub
cp source/IU.html ../apprun/App/IUHub
cp extlibs/IUHub/* ../apprun/App/IUHub
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

cd ../apprun

mono --debug ./App/IUHub/IUHubWeb.exe $*
