#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldwacc.sh $*

cd ../apprun/App/$APPBLDNM

./runwacc.sh $*
