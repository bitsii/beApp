#!/bin/bash

rm -rf ../apprun/App/IUCam/Base

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/IUCam/IUHub_BEX_E.js > ../apprun/App/IUCam/IUHub_BEX_E.js.1
  rm -f ../apprun/App/IUCam/IUHub_BEX_E.js
  mv ../apprun/App/IUCam/IUHub_BEX_E.js.1 ../apprun/App/IUCam/IUHub_BEX_E.js
fi

cd ../apprun/App/IUCam

mv BEX_E_lib_jv.jar BEX_E_lib_jv.ja
mv BEX_E_lui_jv.jar BEX_E_lui_jv.ja

rm *.jar

mv BEX_E_lib_jv.ja BEX_E_lib_jv.jar
mv BEX_E_lui_jv.ja BEX_E_lui_jv.jar

rm ../../../IUCam.zip

cd ..

zip -r IUCam.zip IUCam

cd IUCam

mv -f ../IUCam.zip ../../..

cd ../../../ioturl
