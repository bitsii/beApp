#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldwacc.sh $*

cd ../apprun/App/$APPBLDNM

./runwacc.sh $*
