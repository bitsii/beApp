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
  export CLASSPATH="App/$APPBLDNM/*"
else
  export CLASSPATH="App/$APPBLDNM/*"
fi

export MYPWD=`pwd`

export MYHN=`hostname`

export MYHOME=`echo $HOME`

export MYUSER=`whoami`

mkdir -p Data/$APPBLDNM

while :; do
  java $BEJVRUNARGS -classpath "$CLASSPATH" be.BEL_Base --runParams App/$APPBLDNM/runParamsWa.txt $BERUNARGS $*
    echo "Exited code $?.  Will restart.." >&2
    sleep 2
done
