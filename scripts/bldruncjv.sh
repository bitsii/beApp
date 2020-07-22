#!/bin/bash

export APPBLDNM=${PWD##*/}

../braceApp/scripts/bldcjv.sh $*

cd ../apprun/App/$APPBLDNM

./runcjv.sh $*
