#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldcjv.sh $*

cd ../apprun/App/$APPBLDNM

./runcjv.sh $*
