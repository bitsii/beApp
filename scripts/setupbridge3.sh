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

  export INSDIR=`echo $(getent passwd $INSUSER )| cut -d : -f 6`

fi

if [ "$OSTYPE" == "Darwin" ]; then

  export INSUSER="$USER"
  export INSDIR=`cd;pwd`

fi

if [ "$OSTYPE" == "Linux" ]; then

  echo "Setting Konnectii Bridge to start at boot"
  echo "#!/bin/sh -e" > tmp/stadd
  if [ -e "/etc/rc.local" ]
  then
  cat /etc/rc.local | grep -v "exit " | grep -v "startiuh.sh" | grep -v "#\!/bin" >> tmp/stadd
  fi
  echo "su $INSUSER -c \"$INSDIR/apprun/App/KBridge/startiuh.sh\"" >> tmp/stadd
  echo "exit 0" >> tmp/stadd
  cat tmp/stadd > /etc/rc.local

fi

cd $INSDIR
mkdir apprun/tmp

cd apprun

if [ "$OSTYPE" == "Linux" ]; then
  su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"
  su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"
  if [ "$PRIVATENET" != "n" ]; then
    su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value true"
    su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value false"
  else
    su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value false"
    su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value true"
    cat /etc/ssh/sshd_config  | grep -v "AllowTcpForwarding " | grep -v "GatewayPorts" > tmp/stadd
    echo "AllowTcpForwarding yes" >> tmp/stadd
    echo "GatewayPorts yes" >> tmp/stadd
    cat tmp/stadd > /etc/ssh/sshd_config
    service ssh restart
    service sshd restart
  fi
  su $INSUSER -c "./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.konnectii.com --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  su $INSUSER -c "./App/KBridge/startball.sh"
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
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.konnectii.com --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  mkdir tmp
  echo "@reboot $INSDIR/apprun/App/KBridge/startiuh.sh" > tmp/stadd
  crontab tmp/stadd
  bash -c "./App/KBridge/startball.sh"
fi
