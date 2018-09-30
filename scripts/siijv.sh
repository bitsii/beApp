#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/SII

rm -rf ../apprun/App/SII
mkdir -p ../apprun/App/SII

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/SII/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/SII/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/SII/d --buildPath ../apprun/App/SII --emitLang jv --emitFlag appDebug -mainClass=App:AppStart ../abelii/source/extended/Log.be source/SII.be source/Db.be source/SlDbJv.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be source/WebApp.be

#--emitFlag iuOwnBackground

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abelii/system/jv/be/*.java ../apprun/App/SII/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/SII/d --buildPath ../apprun/App/SII --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abelii/source/extended/Log.be source/SIIBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/SII/Base/target/js/be/BEX_E.js ../apprun/App/SII/IUHub_BEX_E.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#for rel add 
#--outputPlatform linux 
#rm
#--emitFlag appDebug (actually, not ???)
# and change last line from run to rel

#mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/SII/d --buildPath ../apprun/App/SII --emitLang js --ownProcess false -mainClass=SANSite:Wui ../abelii/source/extended/Log.be source/KonSiteBr.be source/SIIBr.be source/BrowserEUI.be

#lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/SII/Base/target/js/be/BEX_E.js ../apprun/App/SII/KonSite_BEX_E.js

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/SII/Base/target/jv
find . -name "*.java" -exec rm {} \;
jar -cf ../../../BEX_E_lui_jv.jar .
cd ../../../../../../edgii

cd ../abelii/system/jv
jar -cf ../../../apprun/App/SII/BEX_E_lib_jv.jar .
cd ../../../edgii

find ../abelii/system -name "*.class" -exec rm {} \;

#common
cp extlibs/SII/* ../apprun/App/SII
cp ../edgii/icons/* ../apprun/App/SII
cp ../edgii/licenses/* ../apprun/App/SII

cp source/SII.html ../apprun/App/SII

#pure 
mkdir -p ../apprun/App/SII/css/layouts
rm -f ../apprun/App/SII/css/layouts/*
cp source/css/layouts/* ../apprun/App/SII/css/layouts
cp source/css/layouts/* ../apprun/App/SII/css/layouts

./scripts/siijvr.sh $*
