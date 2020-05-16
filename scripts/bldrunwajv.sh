#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldwajv.sh $*

cd ../apprun/App/$APPBLDNM

./runwajv.sh $*
