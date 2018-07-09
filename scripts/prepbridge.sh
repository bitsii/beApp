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
  
  echo "Setting Edgii Bridge to start at boot"

fi

if [ "$OSTYPE" == "Linux" ]; then

  echo "Updating software lists"
  dpkg --configure -a
  apt -qq --assume-yes update

  echo "Installing required additional system software"
  apt -qq --assume-yes install fswebcam alsa-utils motion libav-tools
  apt -qq --assume-yes install mpg123 haproxy certbot

  apt -qq --assume-yes install openjdk-9-jdk-headless
  #apt -qq --assume-yes install openjdk-9-jdk
  apt -qq --assume-yes xdg-utils
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen apache2
  
  apt -qq --assume-yes install php7.0 php7.0-gd sqlite php7.0-sqlite php7.0-curl php7.0-bz2 php7.0-cli php7.0-fpm php7.0-intl php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-sqlite3 php7.0-xml php7.0-zip php-apcu php-pear
  
  #apt -qq --assume-yes install python3 python3-venv python3-pip libudev-dev
  #python3 -m pip install wheel
  #pip3 install homeassistant

  apt -qq --assume-yes install fswebcam alsa-utils motion libav-tools
  apt -qq --assume-yes install mpg123 haproxy certbot
  
  apt -qq --assume-yes install openjdk-9-jdk-headless
  #apt -qq --assume-yes install openjdk-9-jdk
  apt -qq --assume-yes xdg-utils
  apt -qq --assume-yes install miniupnpc zip unzip unattended-upgrades screen apache2
  
  apt -qq --assume-yes install php7.0 php7.0-gd sqlite php7.0-sqlite php7.0-curl php7.0-bz2 php7.0-cli php7.0-fpm php7.0-intl php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-sqlite3 php7.0-xml php7.0-zip php-apcu php-pear
  
  #apt -qq --assume-yes install python3 python3-venv python3-pip libudev-dev
  #python3 -m pip install wheel
  #pip3 install homeassistant

  #apt install oracle-java8-jdk 
  #update-java-alternatives -s jdk-8-oracle-arm32-vfp-hflt

  service apache2 restart
  
  mkdir tmp

  echo "Disabling ipv6"
  echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
  echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
  cat tmp/scadd >> /etc/sysctl.conf

fi

su $INSUSER -c "$IZDIR/lilprepbridge.sh"

if [ "$OSTYPE" == "Linux" ]; then
  #chown
  chown -R $INSUSER apprun
  chown -R $INSUSER tmp
  
  cat /etc/ssh/sshd_config  | grep -v "AllowTcpForwarding " | grep -v "GatewayPorts" > tmp/stadd
  echo "AllowTcpForwarding yes" >> tmp/stadd
  echo "GatewayPorts yes" >> tmp/stadd
  cat tmp/stadd > /etc/ssh/sshd_config
  service ssh restart
  service sshd restart
  
fi
