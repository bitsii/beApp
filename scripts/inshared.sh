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

echo ""
echo "Welcome to Konnectii installation.  If you make a mistake hit Ctrl-C to halt"
echo "and then rerun the script to restart"
echo "" 
echo "Please provide desired username and password.  You'll need this to login to"
echo "Konnectii Bridge after install.  This is not yet your Konnectii site login," 
echo "this is the one you want to use to login on this device"
echo -n "Username: "
read inusername
echo ""
echo -n "Password: "
read -s inpassword
echo ""
echo -n "Repeat Password: "
read -s inpassword2
echo ""

if [ "$inpassword" != "$inpassword2" ]; then
echo "Passwords don't match"
exit 1
fi

export INUSR="$inusername"
export INPASS="$inpassword"

echo "Please provide a unique name for the device."
echo "(unique among your devices...)"
echo -n "DeviceName: "
read indname
echo ""
export INDNAME="$indname"

echo "Link bridge to Konnectii to locate and login to bridge on the local network"
echo "and the Internet from https://www.konnectii.com.  Enter the username and password"
echo "you registered on the site - if you have not yet registered an account there pls do so now..."
echo -n "Konnectii username: "
read konuser
echo ""
echo -n "Konnectii Password: "
read -s konpass
echo ""
  
export KONUSER="$konuser"
export KONPASS="$konpass"

if [ "$OSTYPE" == "Darwin" ]; then
  
  echo "Installing required additional system software"
  brew cask install java
  brew install miniupnpc
  brew install wget
  
  echo "Setting Konnectii Bridge to start at boot"

fi

if [ "$OSTYPE" == "Linux" ]; then

  echo "Updating software lists"
  dpkg --configure -a
  apt -qq --assume-yes update

  echo "Installing required additional system software"
  apt -qq --assume-yes install fswebcam alsa-utils motion libav-tools
  apt -qq --assume-yes install mpg123 shellinabox 

  echo "Installing required additional system software"
  apt -qq --assume-yes install openjdk-8-jdk-headless
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen

  apt -qq --assume-yes install openjdk-8-jdk-headless
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen

  #apt install oracle-java8-jdk 
  #update-java-alternatives -s jdk-8-oracle-arm32-vfp-hflt

  #python3-pip hass

  mkdir tmp

  echo "Disabling ipv6"
  echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
  cat tmp/scadd >> /etc/sysctl.conf

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

#mkdir and copy and cd
echo "Preparing application area"
rm -rf $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/Data/KBridge
#copy
cp -r $IZDIR/* $INSDIR/apprun/App/KBridge

cd $INSDIR

cd apprun/App/KBridge

echo "Getting required additional application software"
wget --tries=20 --timeout 20 --retry-connrefused https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.19.3/sqlite-jdbc-3.19.3.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar

chmod +x *.sh

cd $INSDIR

if [ "$OSTYPE" == "Linux" ]; then
  #chown
  chown -R $INSUSER apprun
  chown -R $INSUSER tmp
fi

#su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --hubCmd saveLocalUrl --urlFile localUrl.txt"

if [ "$OSTYPE" == "Linux" ]; then
  su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"
  su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"
  if [ "$PRIVATENET" != "n" ]; then
    su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value true"
    su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value false"
  else
    su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value false"
    su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value true"
  fi
  su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.konnectii.com --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  su $INSUSER -c "./apprun/App/KBridge/startiuh.sh"
fi

if [ "$OSTYPE" == "Darwin" ]; then
  bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"
  bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"
  if [ "$PRIVATENET" != "n" ]; then
    bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value true"
    bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value false"
  else
    bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key doUpnpForward --value false"
    bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key onPublicNet --value true"
  fi
  bash -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --konUrl https://www.konnectii.com --auser $INUSR --konUser $KONUSER --konPass $KONPASS"  
  mkdir tmp
  echo "@reboot $INSDIR/apprun/App/KBridge/startiuh.sh" > tmp/stadd
  crontab tmp/stadd
  bash -c "./apprun/App/KBridge/startiuh.sh"
fi

echo "service is starting now, it may take a few moments to come up"
echo "On the Konnecti site, https://www.konnectii.com, login to your account"
echo "and click the link to your new install under the name you provided.  Then you may login"
echo "using the account you just created during installation"

echo ""

