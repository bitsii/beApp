#!/bin/bash

export OSTYPE=`uname`

if [ "$OSTYPE" == "Linux" ]; then
  if [ "$EUID" -ne 0 ]
    then echo "Please run as root, try running the command 'sudo $0'"
    exit
  fi
fi

export PRIVATENET="y"

export IZDIR=`dirname $0`

$IZDIR/inshared.sh
