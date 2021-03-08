#!/bin/bash

export APPBLDNM=${PWD##*/}

../abeliiApp/scripts/bldwajv.sh $*

cd ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    ./runwajv.bat $*
    ;;
  *)
    ./runwajv.sh $*
    ;;
esac
