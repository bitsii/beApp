#!/bin/bash

export APPBLDNM=${PWD##*/}

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

cd ../..

mkdir -p Data/$APPBLDNM

mkdir -p logs

export MONO_OPTIONS="--debug"
export BEAPPARGS="--runParams App/BPasswd/runParamsWa.txt"
#$BERUNARGS $*
xsp 

#java -classpath "App/$APPBLDNM/*" be.BEX_E --runParams App/$APPBLDNM/runParamsWa.txt $BERUNARGS $*

