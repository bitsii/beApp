#!/bin/bash

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

mkdir -p Data/KBridge

mkdir -p logs

java -classpath "App/KBridge/*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin App:ConfigPlugin --appPlugin KBridge $*

