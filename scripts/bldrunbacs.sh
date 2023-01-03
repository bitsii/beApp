#!/bin/bash

export APPBLDNM=${PWD##*/}

../beApp/scripts/bldbacs.sh $*

cd ../apprun/App/$APPBLDNM

./runbacs.sh $*
