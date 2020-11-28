#!/bin/bash

export APPBLDNM=${PWD##*/}

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then
  export BLDPLAT="macos"
fi

if [ "$OSTYPE" == "Linux" ]; then
  export BLDPLAT="linux"
fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  export BLDPLAT="mswin"
fi

if [ "$BERCDONE" != "true" ]; then
  if [ -e "./build/build${BLDPLAT}rcjv.sh" ]; then
    . "./build/build${BLDPLAT}rcjv.sh"
  fi
fi

rm -rf ../apprun/App/$APPBLDNM/Base

if [ -e ./scripts/prerel.sh ]
then
  ./scripts/prerel.sh
fi

if [ -e ~/node_modules/uglify-js/bin/uglifyjs ]
then
  ~/node_modules/uglify-js/bin/uglifyjs ../apprun/App/$APPBLDNM/BEX_E.js > ../apprun/App/$APPBLDNM/BEX_E.js.1
  lae=$?;if [[ $lae -eq 0 ]]; then
    rm -f ../apprun/App/$APPBLDNM/BEX_E.js
    mv ../apprun/App/$APPBLDNM/BEX_E.js.1 ../apprun/App/$APPBLDNM/BEX_E.js
  fi
fi

if [ -e /usr/local/bin/uglifyjs ]
then
  /usr/local/bin/uglifyjs ../apprun/App/$APPBLDNM/BEX_E.js > ../apprun/App/$APPBLDNM/BEX_E.js.1
  lae=$?;if [[ $lae -eq 0 ]]; then
    rm -f ../apprun/App/$APPBLDNM/BEX_E.js
    mv ../apprun/App/$APPBLDNM/BEX_E.js.1 ../apprun/App/$APPBLDNM/BEX_E.js
  fi
fi

cd ../apprun/App/$APPBLDNM

mkdir bereljar
mv BEX_*jar bereljar

rm *.jar

mv bereljar/* .
rmdir bereljar

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
