#!/bin/bash

export OSTYPE=`uname`

export IZDIR=`dirname $0`

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
  apt -qq --assume-yes install mpg123 shellinabox haproxy certbot

  apt -qq --assume-yes install openjdk-9-jdk-headless
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen nginx nginx-common
  
  python3-pip hass

  apt -qq --assume-yes install fswebcam alsa-utils motion libav-tools
  apt -qq --assume-yes install mpg123 shellinabox haproxy certbot
  
  apt -qq --assume-yes install openjdk-9-jdk-headless
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen nginx nginx-common
  
  python3-pip hass

  #apt install oracle-java8-jdk 
  #update-java-alternatives -s jdk-8-oracle-arm32-vfp-hflt

  mkdir tmp

  echo "Disabling ipv6"
  echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
  cat tmp/scadd >> /etc/sysctl.conf

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
mkdir -p apprun/tmp

if [ "$OSTYPE" == "Linux" ]; then
  #chown
  chown -R $INSUSER apprun
  chown -R $INSUSER tmp
  
  echo "Setting Konnectii Bridge to start at boot"
  echo "#!/bin/sh -e" > tmp/stadd
  if [ -e "/etc/rc.local" ]
  then
  cat /etc/rc.local | grep -v "exit " | grep -v "startiuh.sh" | grep -v "#\!/bin" >> tmp/stadd
  fi
  echo "su $INSUSER -c \"$INSDIR/apprun/App/KBridge/startiuh.sh\"" >> tmp/stadd
  echo "exit 0" >> tmp/stadd
  cat tmp/stadd > /etc/rc.local
  
  cat /etc/ssh/sshd_config  | grep -v "AllowTcpForwarding " | grep -v "GatewayPorts" > tmp/stadd
  echo "AllowTcpForwarding yes" >> tmp/stadd
  echo "GatewayPorts yes" >> tmp/stadd
  cat tmp/stadd > /etc/ssh/sshd_config
  service ssh restart
  service sshd restart
  
fi
