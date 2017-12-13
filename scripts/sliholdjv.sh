#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/SLIHold

rm -rf ../apprun/App/SLIHold
mkdir -p ../apprun/App/SLIHold

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/SLIHold/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/SLIHold/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/SLIHold/d --buildPath ../apprun/App/SLIHold --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/SLIHold.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/SLIHold/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/SLIHold/d --buildPath ../apprun/App/SLIHold --emitLang js --ownProcess false -mainClass=SLIHold:Wui ../abe-pl/source/extended/Log.be source/SLIHoldBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/SLIHold/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/SLIHold/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#
cp ../apprun/App/SLIHold/Base/target/js/be/BEX_E.js ../apprun/App/SLIHold/SLIHold_BEX_E.js
cp source/SLIHold*.html ../apprun/App/SLIHold
cp extlibs/SLIHold/* ../apprun/App/SLIHold
cp icons/* ../apprun/App/SLIHold
cp licenses/* ../apprun/App/SLIHold

mkdir -p ../apprun/App/SLIHold/css/layouts
rm -f ../apprun/App/SLIHold/css/layouts/*
cp source/css/layouts/* ../apprun/App/SLIHold/css/layouts

./scripts/sliholdjvrun.sh $*
