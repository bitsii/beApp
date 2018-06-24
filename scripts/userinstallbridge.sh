#!/bin/bash

export OSTYPE=`uname`

if [ "$OSTYPE" == "Linux" ]; then

  if [ "$EUID" -eq 0 ]
    then echo "Please do not run user install as root, run as the user the service will run as."
    exit
  fi

  export INSUSER="$USER"

  export INSDIR=`echo $(getent passwd $INSUSER )| cut -d : -f 6`

fi

export IZDIR=`dirname $0`

echo "First we'll install some prerequisite packages and then ask for" 
echo "initial setup information.  This may take awhile" 
echo "depending on the speed of your internet connection."
sleep 5

$IZDIR/lilprepbridge.sh
$IZDIR/setupbridge.sh

echo ""
