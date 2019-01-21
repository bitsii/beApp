#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

export OSTYPE=`uname`

if [ "$OSTYPE" == "Linux" ]; then

  if [ "$EUID" -eq 0 ]
    then echo "Please do not run setup as root, run as the user the service will run as."
    exit
  fi

  export INSUSER="$USER"

  export INSDIR=`echo $(getent passwd $INSUSER )| cut -d : -f 6`

fi

if [ "$OSTYPE" == "Darwin" ]; then

  export INSUSER="$USER"
  export INSDIR=`cd;pwd`

fi

cd $INSDIR
mkdir -p apprun/tmp
cd apprun

if [ "$OSTYPE" == "Linux" ]; then
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"
  if [ "$PRIVATENET" != "n" ]; then
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value true"
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value false"
  else
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value false"
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value true"
  fi
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.abelii.net --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  mkdir -p tmp
  echo "@reboot bash -l -c '$INSDIR/apprun/App/KBridge/startiuh.sh'" > tmp/stadd
  crontab tmp/stadd
  sudo cp -f ./App/KBridge/noinetreboot.sh /etc/cron.daily
  sudo cp -f ./App/KBridge/nobridgereboot.sh /etc/cron.daily
  bash -c "./App/KBridge/startball.sh"
fi

if [ "$OSTYPE" == "Darwin" ]; then
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"
  if [ "$PRIVATENET" != "n" ]; then
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value true"
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value false"
  else
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value false"
    bash -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value true"
  fi
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.abelii.net --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  mkdir -p tmp
  echo "@reboot bash -l -c '$INSDIR/apprun/App/KBridge/startiuh.sh'" > tmp/stadd
  crontab tmp/stadd
  bash -c "./App/KBridge/startball.sh"
fi
