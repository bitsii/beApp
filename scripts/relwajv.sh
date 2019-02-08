#!/bin/bash

export APPBLDNM=${PWD##*/}

rm -rf ../apprun/App/$APPBLDNM/Base

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/$APPBLDNM/BEX_E.js > ../apprun/App/$APPBLDNM/BEX_E.js.1
  rm -f ../apprun/App/$APPBLDNM/BEX_E.js
  mv ../apprun/App/$APPBLDNM/BEX_E.js.1 ../apprun/App/$APPBLDNM/BEX_E.js
fi

if [ -e /usr/local/bin/uglifyjs ]
then
  /usr/local/bin/uglifyjs ../apprun/App/$APPBLDNM/BEX_E.js > ../apprun/App/$APPBLDNM/BEX_E.js.1
  rm -f ../apprun/App/$APPBLDNM/BEX_E.js
  mv ../apprun/App/$APPBLDNM/BEX_E.js.1 ../apprun/App/$APPBLDNM/BEX_E.js
fi

cd ../apprun/App/$APPBLDNM

mv BEX_E_lib_jv.jar BEX_E_lib_jv.ja
mv BEX_E_app_jv.jar BEX_E_app_jv.ja

rm *.jar

mv BEX_E_lib_jv.ja BEX_E_lib_jv.jar
mv BEX_E_app_jv.ja BEX_E_app_jv.jar

rm ../../../$APPBLDNM.zip

cd ..

zip -r $APPBLDNM.zip $APPBLDNM

cd $APPBLDNM

mv -f ../$APPBLDNM.zip ../../..

cd ../../../$APPBLDNM
