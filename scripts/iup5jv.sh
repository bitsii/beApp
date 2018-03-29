#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/WRProxy

rm -rf ../apprun/App/WRProxy
mkdir -p ../apprun/App/WRProxy

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/WRProxy/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/WRProxy/*"
    ;;
esac

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/WRProxy/d --buildPath ../apprun/App/WRProxy --emitLang jv --emitFlag iuDebug -mainClass=App:AppStart ../abe-pl/source/extended/Log.be source/IU.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/WRProxy/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#for rel add 
# --outputPlatform linux 
#rm
# --emitFlag iuDebug 
# and change last line from run to rel

cd ../apprun/App/WRProxy/Base/target/jv
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/WRProxy/BEX_E_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

cp extlibs/WRProxy/* ../apprun/App/WRProxy
cp licenses/* ../apprun/App/WRProxy

./scripts/iup5jvrun.sh $*

#./scripts/iucrel.sh
