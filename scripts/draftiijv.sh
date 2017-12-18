#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/Draftii

rm -rf ../apprun/App/Draftii
mkdir -p ../apprun/App/Draftii

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/Draftii/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/Draftii/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/Draftii/d --buildPath ../apprun/App/Draftii --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/Draftii.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/Draftii/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/Draftii/d --buildPath ../apprun/App/Draftii --emitLang js --ownProcess false -mainClass=Draftii:Wui ../abe-pl/source/extended/Log.be source/DraftiiBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/Draftii/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/Draftii/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#
cp ../apprun/App/Draftii/Base/target/js/be/BEX_E.js ../apprun/App/Draftii/Draftii_BEX_E.js
cp source/Draftii*.html ../apprun/App/Draftii
cp extlibs/Draftii/* ../apprun/App/Draftii
cp icons/* ../apprun/App/Draftii
cp licenses/* ../apprun/App/Draftii

mkdir -p ../apprun/App/Draftii/css/layouts
rm -f ../apprun/App/Draftii/css/layouts/*
cp source/css/layouts/* ../apprun/App/Draftii/css/layouts

./scripts/draftiijvrun.sh $*
