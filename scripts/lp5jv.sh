#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/LocPing
mkdir -p ../apprun/App/LocPing

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/App/LocPing/d --buildPath ../apprun/App/LocPing --emitLang jv -mainClass=App:LocPing --emitFlag foo source/LocPing.be source/BrowserUI.be source/BrowserJvFx.be source/App.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../be/system/jv/be/BELS_Base/*.java ../apprun/App/LocPing/Base/target/jv/be/BEL_4_Base/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/App/LocPing/d --buildPath ../apprun/App/LocPing --emitLang js --ownProcess false -mainClass=App:LocPing:LPBr source/LocPingBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/LocPing/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/App/LocPing/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

cp ../apprun/App/LocPing/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/App/LocPing
cp source/LocPing.html ../apprun/App/LocPing

rm -rf ../apprun/App/LocPing/Base

./scripts/jp5jvrun.sh $*
