#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/Dz
mkdir -p ../apprun/App/Dz

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/App/Dzd --buildPath ../apprun/App/Dz --emitLang jv  --outputPlatform linux -mainClass=Dz:Ui source/DzTest.be source/DzUi.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac -classpath extlibs/jetty/*:extlibs/hsqldb/*:extlibs/bcastlejv/*:extlibs/javamail/* ../be/system/jv/be/BELS_Base/*.java ../apprun/App/Dz/Base/target/jv/be/BEL_4_Base/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/App/Dzd --buildPath ../apprun/App/Dz --emitLang js --outputPlatform linux --ownProcess false -mainClass=Dz:Eui source/DzEui.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/Dz/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/App/Dz/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

cp ../apprun/App/Dz/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/App/Dz
cp scripts/uppic.sh ../apprun/App/Dz
cp scripts/uppic.bat ../apprun/App/Dz
cp scripts/upgrade.bat ../apprun/App/Dz
cp scripts/postupgrade.bat ../apprun/App/Dz
cp scripts/upgrade.sh ../apprun/App/Dz
cp scripts/upgrade2.sh ../apprun/App/Dz
cp scripts/postupgrade.sh ../apprun/App/Dz
cp scripts/getcams.sh ../apprun/App/Dz
cp scripts/getcams.bat ../apprun/App/Dz
cp scripts/startdz.sh ../apprun/App/Dz
cp scripts/dzrun.sh ../apprun/App/Dz
cp scripts/dzcmdrs.sh ../apprun/App/Dz
cp scripts/dzcmd.sh ../apprun/App/Dz
cp scripts/motionrun.sh ../apprun/App/Dz
cp scripts/camclean.sh ../apprun/App/Dz
cp source/Dz*.html ../apprun/App/Dz
cp source/Version.txt ../apprun/App/Dz
cp source/MOCAM.conf ../apprun/App/Dz
cp extlibs/jetty/* ../apprun/App/Dz
cp extlibs/hsqldb/* ../apprun/App/Dz
cp extlibs/bcastlejv/* ../apprun/App/Dz
cp extlibs/javamail/* ../apprun/App/Dz

rm -rf ../apprun/App/Dz/Base

#./scripts/dz5jvrun.sh $*

./scripts/relprep.sh
