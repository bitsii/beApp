#!/bin/bash

export APPBLDNM=${PWD##*/}

cd ../..

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then

  export PATH=$PATH:/usr/sbin:/usr/local/bin

fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  echo "Is Mingw"
  export OSTYPE="Mingw"
fi

export MYPWD=`pwd`

export MYHN=`hostname`

export MYHOME=`echo $HOME`

export MYUSER=`whoami`

mkdir -p Data/$APPBLDNM

mkdir -p logs

java -classpath "App/$APPBLDNM/*" be.BEX_E --runParams App/$APPBLDNM/runParams.txt $*

