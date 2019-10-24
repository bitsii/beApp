#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldwajv.sh $*

cd ../apprun/App/$APPBLDNM

./runwajv.sh $*
