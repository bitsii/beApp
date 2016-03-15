#!/bin/bash

uglifyjs ../apprun/App/Dz/BEL_4_Base.js > ../apprun/App/Dz/BEL_4_Base.js.1

rm -f ../apprun/App/Dz/BEL_4_Base.js

mv ../apprun/App/Dz/BEL_4_Base.js.1 ../apprun/App/Dz/BEL_4_Base.js

cd ../apprun/App/Dz

rm -f ../../../Dz.zip

zip ../../../Dz.zip *

cd ../../../app
