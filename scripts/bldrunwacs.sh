#!/bin/bash

export APPBLDNM=${PWD##*/}

../beApp/scripts/bldwacs.sh $*

cd ../apprun/App/$APPBLDNM

./runwacs.sh $*
