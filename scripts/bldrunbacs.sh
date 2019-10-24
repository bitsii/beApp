#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldbacs.sh $*

cd ../apprun/App/$APPBLDNM

./runbacs.sh $*
