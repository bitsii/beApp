#!/bin/bash

export OSTYPE=`uname`

if [ "$OSTYPE" == "Linux" ]; then
  if [ "$EUID" -ne 0 ]
    then echo "Please run as root, try running the command 'sudo $0'"
    exit
  fi
  
  if [ -n "$SUDO_USER" ]; then
    export INSUSER="$SUDO_USER"
  else
    export INSUSER="$USER"
  fi
  
fi

export IZDIR=`dirname $0`

echo "First we'll install some prerequisite packages and then ask for" 
echo "initial setup information.  This may take awhile" 
echo "depending on the speed of your internet connection."
sleep 5

$IZDIR/prepbridge.sh
su $INSUSER -c "$IZDIR/setupbridge.sh"

echo ""
