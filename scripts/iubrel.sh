#!/bin/bash

rm -rf ../apprun/App/IUHub/Base

uglifyjs ../apprun/App/IUHub/IUHub_BEL_4_Base.js > ../apprun/App/IUHub/IUHub_BEL_4_Base.js.1
rm -f ../apprun/App/IUHub/IUHub_BEL_4_Base.js
mv ../apprun/App/IUHub/IUHub_BEL_4_Base.js.1 ../apprun/App/IUHub/IUHub_BEL_4_Base.js

uglifyjs ../apprun/App/IUHub/IUCam_BEL_4_Base.js > ../apprun/App/IUHub/IUCam_BEL_4_Base.js.1
rm -f ../apprun/App/IUHub/IUCam_BEL_4_Base.js
mv ../apprun/App/IUHub/IUCam_BEL_4_Base.js.1 ../apprun/App/IUHub/IUCam_BEL_4_Base.js

cd ../apprun/App/IUHub

rm ../../../IUBHub.zip

zip ../IUBHub.zip ./*

mv -f ../IUBHub.zip ../../..

cd ../../../ioturl
