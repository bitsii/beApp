#!/bin/bash

rm -rf ../apprun/App/KBridge/Base

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/KBridge/IUHub_BEX_E.js > ../apprun/App/KBridge/IUHub_BEX_E.js.1
  rm -f ../apprun/App/KBridge/IUHub_BEX_E.js
  mv ../apprun/App/KBridge/IUHub_BEX_E.js.1 ../apprun/App/KBridge/IUHub_BEX_E.js
fi

if [ -e /usr/local/bin/uglifyjs ]
then
  /usr/local/bin/uglifyjs ../apprun/App/KBridge/IUHub_BEX_E.js > ../apprun/App/KBridge/IUHub_BEX_E.js.1
  rm -f ../apprun/App/KBridge/IUHub_BEX_E.js
  mv ../apprun/App/KBridge/IUHub_BEX_E.js.1 ../apprun/App/KBridge/IUHub_BEX_E.js
fi

cd ../apprun/App/KBridge

mv BEX_E_lib_jv.jar BEX_E_lib_jv.ja
mv BEX_E_lui_jv.jar BEX_E_lui_jv.ja

rm *.jar

mv BEX_E_lib_jv.ja BEX_E_lib_jv.jar
mv BEX_E_lui_jv.ja BEX_E_lui_jv.jar

rm ../../../KBridge.zip

cd ..

zip -r KBridge.zip KBridge

cd KBridge

mv -f ../KBridge.zip ../../..

cd ../../../edgii

cd ..

rm -rf kinsarch
rm -f InstallBridgeLinux.exe

mkdir kinsarch
cp KBridge.zip kinsarch
cp edgii/scripts/karchrun.sh kinsarch
chmod +x kinsarch/karchrun.sh

makeself kinsarch InstallBridgeLinux.exe KBridgeInstall ./karchrun.sh
