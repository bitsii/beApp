#!/bin/bash

export APPBLDNM=${PWD##*/}

cd ..

rm -rf ${APPBLDNM}_appins
rm -f Install${APPBLDNM}.exe

mkdir ${APPBLDNM}_appins
cp $APPBLDNM.zip ${APPBLDNM}_appins
cp $APPBLDNM/resources/relwajvins.sh ${APPBLDNM}_appins
chmod +x ${APPBLDNM}_appins/relwajvins.sh

makeself ${APPBLDNM}_appins Install${APPBLDNM}.exe ${APPBLDNM}Install ./relwajvins.sh

cd ${APPBLDNM}
