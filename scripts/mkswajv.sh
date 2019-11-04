#!/bin/bash

export APPBLDNM=${PWD##*/}

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
