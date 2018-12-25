#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/BC

rm -rf ../apprun/App/BC
mkdir -p ../apprun/App/BC

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/BC/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/BC/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/BC/d --buildPath ../apprun/App/BC --emitLang jv --emitFlag appDebug -mainClass=App:AppStart ../abelii/source/extended/Log.be source/BC.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abelii/system/jv/be/*.java ../apprun/App/BC/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/BC/d --buildPath ../apprun/App/BC --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abelii/source/extended/Log.be source/BCBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/BC/Base/target/js/be/BEX_E.js ../apprun/App/BC/IUHub_BEX_E.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#for rel add 
#--outputPlatform linux 
#rm
#--emitFlag appDebug (actually, not ???)
# and change last line from run to rel

#mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/BC/d --buildPath ../apprun/App/BC --emitLang js --ownProcess false -mainClass=SANSite:Wui ../abelii/source/extended/Log.be source/KonSiteBr.be source/BCBr.be source/BrowserEUI.be

#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/BC/Base/target/js/be/BEX_E.js ../apprun/App/BC/KonSite_BEX_E.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/BC/Base/target/jv
find . -name "*.java" -exec rm {} \;
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../edgii

cd ../abelii/system/jv
jar -cf ../../../apprun/App/BC/BEX_E_lib_jv.jar .
cd ../../../edgii

find ../abelii/system -name "*.class" -exec rm {} \;

#common
cp extlibs/BC/* ../apprun/App/BC
cp ../edgii/icons/* ../apprun/App/BC
cp ../edgii/licenses/* ../apprun/App/BC

cp source/BC.html ../apprun/App/BC

#pure 
mkdir -p ../apprun/App/BC/css/layouts
rm -f ../apprun/App/BC/css/layouts/*
cp source/css/layouts/* ../apprun/App/BC/css/layouts
cp source/css/layouts/* ../apprun/App/BC/css/layouts

./scripts/bcjvr.sh $*
