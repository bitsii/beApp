#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/IUHub
mkdir -p ../apprun/App/IUHub

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/App/IUHubd --buildPath ../apprun/App/IUHub --emitLang jv -mainClass=IUHub:Ui source/IUHubTest.be source/IUHub.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac -classpath extlibs/IUHub/* ../be/system/jv/be/BELS_Base/*.java ../apprun/App/IUHub/Base/target/jv/be/BEL_4_Base/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/App/IUHubd --buildPath ../apprun/App/IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUHub/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/App/IUHub/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

cp ../apprun/App/IUHub/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/App/IUHub
cp scripts/uppic.sh ../apprun/App/IUHub
cp scripts/uppic.bat ../apprun/App/IUHub
cp scripts/upgrade.bat ../apprun/App/IUHub
cp scripts/postupgrade.bat ../apprun/App/IUHub
cp scripts/upgrade.sh ../apprun/App/IUHub
cp scripts/upgrade2.sh ../apprun/App/IUHub
cp scripts/postupgrade.sh ../apprun/App/IUHub
cp scripts/getcams.sh ../apprun/App/IUHub
cp scripts/getcams.bat ../apprun/App/IUHub
cp scripts/startiuh.sh ../apprun/App/IUHub
cp scripts/iuhrun.sh ../apprun/App/IUHub
cp scripts/iuhcmdrs.sh ../apprun/App/IUHub
cp scripts/iuhcmd.sh ../apprun/App/IUHub
cp scripts/motionrun.sh ../apprun/App/IUHub
cp scripts/camclean.sh ../apprun/App/IUHub
cp source/IUHub*.html ../apprun/App/IUHub
cp source/Version.txt ../apprun/App/IUHub
cp source/MOCAM.conf ../apprun/App/IUHub
cp extlibs/IUHub/* ../apprun/App/IUHub

rm -rf ../apprun/App/IUHub/Base

./scripts/iuh5jvrun.sh $*
