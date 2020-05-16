#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldwacs.sh $*

cd ../apprun/App/$APPBLDNM

./runwacs.sh $*
