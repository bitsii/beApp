#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldbacsdt.sh $*

cd ../apprun/App/$APPBLDNM

./runbacsdt.sh $*
