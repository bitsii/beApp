#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldwacs.sh $*

cd ../apprun/App/$APPBLDNM

./runwacs.sh $*
