#!/bin/bash

uglifyjs ../apprun/App/IUHub/BEL_4_Base.js > ../apprun/App/IUHub/BEL_4_Base.js.1

rm -f ../apprun/App/IUHub/BEL_4_Base.js

mv ../apprun/App/IUHub/BEL_4_Base.js.1 ../apprun/App/IUHub/BEL_4_Base.js

cd ../apprun/App/IUHub

rm -f ../../../IUHub.zip

zip ../IUHub.zip ./*

mv ../IUHub.zip ../../..

cd ../../../app
