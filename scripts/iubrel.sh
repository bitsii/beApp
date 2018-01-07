#!/bin/bash

rm -rf ../apprun/App/IUHub/Base

#~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/IUHub/IUHub_BEX_E.js > ../apprun/App/IUHub/IUHub_BEX_E.js.1
#rm -f ../apprun/App/IUHub/IUHub_BEX_E.js
#mv ../apprun/App/IUHub/IUHub_BEX_E.js.1 ../apprun/App/IUHub/IUHub_BEX_E.js

cd ../apprun/App/IUHub

mv BEX_E_lib_jv.jar BEX_E_lib_jv.ja
mv BEX_E_lui_jv.jar BEX_E_lui_jv.ja

rm *.jar

mv BEX_E_lib_jv.ja BEX_E_lib_jv.jar
mv BEX_E_lui_jv.ja BEX_E_lui_jv.jar

rm ../../../IUBHub.zip

cd ..

zip -r IUBHub.zip IUHub

cd IUHub

mv -f ../IUBHub.zip ../../..

cd ../../../ioturl
