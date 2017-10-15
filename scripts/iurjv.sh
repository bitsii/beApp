#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/Iur

rm -rf ../apprun/App/Iur
mkdir -p ../apprun/App/Iur

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/Iur/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/Iur/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/Iur/d --buildPath ../apprun/App/Iur --emitFlag iuDebug --emitLang jv -mainClass=Iur:AGSStart ../abe-pl/source/extended/Log.be source/Iur.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserUI.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/Iur/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/Iur/d --buildPath ../apprun/App/Iur --emitLang js --ownProcess false -mainClass=Iur:Eui ../abe-pl/source/extended/Log.be source/IurBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/Iur/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/Iur/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/Iur/Base/target/js/be/BEX_E.js ../apprun/App/Iur/Iur_BEX_E.js
cp source/Iur*.html ../apprun/App/Iur
cp extlibs/Iur/* ../apprun/App/Iur
cp icons/* ../apprun/App/Iur
cp licenses/* ../apprun/App/Iur

./scripts/iurjvrun.sh $*
