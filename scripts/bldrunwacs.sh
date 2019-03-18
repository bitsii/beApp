#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldwacs.sh $*

cd csaweb/csaweb/App/$APPBLDNM

./runwacs.sh $*
