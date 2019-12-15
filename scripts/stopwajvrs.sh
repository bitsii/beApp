#!/bin/bash

cd "${0%/*}"

export APPBLDNM=${PWD##*/}

cd ../..

export APPRUNDIR=${PWD}
#echo $APPRUNDIR

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then

  export PATH=$PATH:/usr/sbin:/usr/local/bin

fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  #echo "Is Mingw"
  export OSTYPE="Mingw"
fi

if [ "$OSTYPE" == "Darwin" ]; then
  lsof -d cwd | grep $APPRUNDIR | grep java | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} ps -fe {} | grep $APPBLDNM | awk '{$1=$1}1' | cut -d " " -f 3 | xargs -I{} kill {}
  lsof -d cwd | grep $APPRUNDIR | grep java | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} ps -fe {} | grep $APPBLDNM | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} kill {}
fi

if [ "$OSTYPE" == "Linux" ]; then
  lsof -d cwd | grep $APPRUNDIR | grep java | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} ps -feq {} | grep $APPBLDNM | awk '{$1=$1}1' | cut -d " " -f 3 | xargs -I{} kill {}
  lsof -d cwd | grep $APPRUNDIR | grep java | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} ps -feq {} | grep $APPBLDNM | awk '{$1=$1}1' | cut -d " " -f 2 | xargs -I{} kill {}
fi
