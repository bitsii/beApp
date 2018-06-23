#!/bin/bash

rm -rf ../apprun/App/KBridge/Base

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/KBridge/IUHub_BEX_E.js > ../apprun/App/KBridge/IUHub_BEX_E.js.1
  rm -f ../apprun/App/KBridge/IUHub_BEX_E.js
  mv ../apprun/App/KBridge/IUHub_BEX_E.js.1 ../apprun/App/KBridge/IUHub_BEX_E.js
fi

cd ../apprun/App/KBridge

mv BEX_E_lib_jv.jar BEX_E_lib_jv.ja
mv BEX_E_lui_jv.jar BEX_E_lui_jv.ja

rm *.jar

mv BEX_E_lib_jv.ja BEX_E_lib_jv.jar
mv BEX_E_lui_jv.ja BEX_E_lui_jv.jar

rm ../../../KBridgeMO.zip

cd ..

zip -r KBridgeMO.zip KBridge

cd KBridge

mv -f ../KBridgeMO.zip ../../..

cd ../../../edgii
