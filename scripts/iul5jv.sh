#!/bin/bash

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data

rm -rf ../apprun/App/IUHub
mkdir -p ../apprun/App/IUHub

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abe-pl/target5/*;extlibs/IUHub/*"
    ;;
  *)
    export CLASSPATH="../abe-pl/target5/*:extlibs/IUHub/*"
    ;;
esac

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang jv -mainClass=IULink:LinkStart ../abe-pl/source/extended/Log.be source/IU.be source/IUHub.be source/IULink.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/App.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac ../abe-pl/system/jv/be/*.java ../apprun/App/IUHub/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui ../abe-pl/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/IUHub/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../ioturl

cd ../abe-pl/system/jv
jar -cf ../../../apprun/App/IUHub/BEL_4_Base_lib_jv.jar .
cd ../../../ioturl

find ../abe-pl/system -name "*.class" -exec rm {} \;

#hub
cp ../apprun/App/IUHub/Base/target/js/be/BEL_4_Base.js ../apprun/App/IUHub/IUHub_BEL_4_Base.js
cp source/IU.html ../apprun/App/IUHub
cp extlibs/IUHub/* ../apprun/App/IUHub
cp icons/* ../apprun/App/IUHub
cp LICENSE.txt ../apprun/App/IUHub
cp LICENSE-MPL.txt ../apprun/App/IUHub

./scripts/iub5jvrun.sh $*
