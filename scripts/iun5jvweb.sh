#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/Nopa

rm -rf ../apprun/App/Nopa
mkdir -p ../apprun/App/Nopa

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/NopaWeb/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/NopaWeb/*"
    ;;
esac

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/Nopa/d --buildPath ../apprun/App/Nopa --emitFlag iuDebug --emitLang jv -mainClass=Nopa:WebStart ../abe-pl/source/extended/Log.be source/IU.be source/Nopa.be source/Db.be source/BrowserUI.be source/WebServer.be source/App.be source/WebApp.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/Nopa/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/Nopa/d --buildPath ../apprun/App/Nopa --emitLang js --ownProcess false -mainClass=Nopa:Eui ../abe-pl/source/extended/Log.be source/NopaBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/Nopa/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/Nopa/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#nopa
cp ../apprun/App/Nopa/Base/target/js/be/BEX_E.js ../apprun/App/Nopa/Nopa_BEX_E.js
cp source/Nopa.html ../apprun/App/Nopa
cp extlibs/NopaWeb/* ../apprun/App/Nopa
cp icons/* ../apprun/App/Nopa
cp licenses/* ../apprun/App/Nopa

./scripts/iun5jvrun.sh $*
