#!/bin/bash

cd "${0%/*}"

export APPBLDNM=${PWD##*/}

cd ../..

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then

  export PATH=$PATH:/usr/sbin:/usr/local/bin

fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  #echo "Is Mingw"
  export OSTYPE="Mingw"
fi

export MYPWD=`pwd`

export MYHN=`hostname`

export MYHOME=`echo $HOME`

export MYUSER=`whoami`

mkdir -p Data/$APPBLDNM

mono --debug App/$APPBLDNM/BEX_E_mcs.exe --runParams App/$APPBLDNM/runParamsCa.txt $BERUNARGS $*