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

if [ -z "$APPPKGNM" ]
then
  APPPKGNM=${APPBLDNM}.zip
fi

if [ -z "$APPINSNM" ]
then
  APPINSNM=Install${APPBLDNM}.exe
fi

cd ..

rm -rf ${APPBLDNM}_appins
rm -f $APPINSNM

mkdir ${APPBLDNM}_appins
cp $APPPKGNM ${APPBLDNM}_appins
cp $APPBLDNM/resources/relwajvins.sh ${APPBLDNM}_appins
chmod +x ${APPBLDNM}_appins/relwajvins.sh

if [ -e ./$APPBLDNM/scripts/premks.sh ]
then
  ./$APPBLDNM/scripts/premks.sh
fi

makeself ${APPBLDNM}_appins $APPINSNM ${APPBLDNM}Install ./relwajvins.sh

cd ${APPBLDNM}
