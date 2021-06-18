#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldbajv.sh $*

cd ../apprun/App/$APPBLDNM

./runbajv.sh $*
