#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, try running the command 'sudo $0'"
  exit
fi

export PRIVATENET="n"

export IZDIR=`dirname $0`

$IZDIR/inshared.sh
