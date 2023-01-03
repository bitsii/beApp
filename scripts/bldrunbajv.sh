#!/bin/bash

export APPBLDNM=${PWD##*/}

../beApp/scripts/bldbajv.sh $*

cd ../apprun/App/$APPBLDNM

./runbajv.sh $*
