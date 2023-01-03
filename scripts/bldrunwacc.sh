#!/bin/bash

export APPBLDNM=${PWD##*/}

../beApp/scripts/bldwacc.sh $*

cd ../apprun/App/$APPBLDNM

./runwacc.sh $*
