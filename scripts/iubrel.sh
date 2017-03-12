#!/bin/bash

rm -rf ../apprun/App/IUHub/Base

uglifyjs ../apprun/App/IUHub/IUHub_BEL_4_Base.js > ../apprun/App/IUHub/IUHub_BEL_4_Base.js.1
rm -f ../apprun/App/IUHub/IUHub_BEL_4_Base.js
mv ../apprun/App/IUHub/IUHub_BEL_4_Base.js.1 ../apprun/App/IUHub/IUHub_BEL_4_Base.js

cd ../apprun/App/IUHub

mv BEL_4_Base_lib_jv.jar BEL_4_Base_lib_jv.ja
mv BEL_4_Base_lui_jv.jar BEL_4_Base_lui_jv.ja

rm *.jar

mv BEL_4_Base_lib_jv.ja BEL_4_Base_lib_jv.jar
mv BEL_4_Base_lui_jv.ja BEL_4_Base_lui_jv.jar

rm ../../../IUBHub.zip

zip ../IUBHub.zip ./*

mv -f ../IUBHub.zip ../../..

cd ../../../ioturl
