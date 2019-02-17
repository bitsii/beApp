#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldbajv.sh $*

cd ../apprun/App/$APPBLDNM

./runbajv.sh $*
