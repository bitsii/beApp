#!/bin/bash

rm -rf targetAd
mkdir -p targetAd

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/IUHubAd/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/IUHubAd/*"
    ;;
esac

java be.BEX_E ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath targetAd/d --buildPath targetAd --emitFlag platDroid --emitFlag appDebug --emitLang jv --outputPlatform linux -mainClass=IUHub:HubStart ../abelii/source/extended/Log.be source/IU.be source/IUHub.be source/Db.be source/BrowserUI.be source/BrowserJvAd.be source/App.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf android/IUHub/app/src/main/java/be
mv targetAd/Base/target/jv/be android/IUHub/app/src/main/java/
cp ../abelii/system/jv/be/*java android/IUHub/app/src/main/java/be

rm -rf android/IUHub/app/libs/
mkdir -p android/IUHub/app/libs/
cp extlibs/IUHubAd/* android/IUHub/app/libs/

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEX_E ../abelii/source/base/Uses.be --buildFile build/base.txt --deployPath ../apprun/App/IUHub/d --buildPath ../apprun/App/IUHub --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUHub:Eui ../abelii/source/extended/Log.be source/IUHubBr.be source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf android/IUHub/app/src/main/assets/App/IUHub
mkdir -p android/IUHub/app/src/main/assets/App/IUHub

cp ../apprun/App/IUHub/Base/target/js/be/BEX_E.js android/IUHub/app/src/main/assets/App/IUHub/IUHub_BEX_E.js
cp source/IU.html android/IUHub/app/src/main/assets/App/IUHub
cp icons/* android/IUHub/app/src/main/assets/App/IUHub
cp licenses/* android/IUHub/app/src/main/assets/App/IUHub
