#!/bin/bash

cd "${0%/*}"

export APPBLDNM=${PWD##*/}

cd ..

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then

  export PATH=$PATH:/usr/sbin:/usr/local/bin

fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  #echo "Is Mingw"
  export OSTYPE="Mingw"
  export CLASSPATH="njv/*"
else
  export CLASSPATH="njv/*"
fi

export MYPWD=`pwd`

export MYHN=`hostname`

export MYHOME=`echo $HOME`

export MYUSER=`whoami`

java -classpath "$CLASSPATH" be.BEL_Base $*

