#!/bin/bash

export APPBLDNM=${PWD##*/}

cd cswa
dotnet publish -o ../../apprun/App/$APPBLDNM --self-contained -r $BRCSRT
lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
cd ..

cp -f ../braceApp/scripts/runwacssc.sh ../apprun/App/$APPBLDNM/runwacs.sh

rm -rf ../apprun/App/$APPBLDNM/Base

if [ -e ./scripts/prerel.sh ]
then
  ./scripts/prerel.sh
fi

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

if [ -z "$APPPKGNM" ]
then
  APPPKGNM=${APPBLDNM}.zip
fi

rm ../../../$APPPKGNM

cd ..

zip -r $APPPKGNM $APPBLDNM

cd $APPBLDNM

mv -f ../$APPPKGNM ../../..

cd ../../../$APPBLDNM
