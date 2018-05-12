#!/bin/bash

#prep the sd card for iukh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, try running the command 'sudo $0'"
  exit
fi

export INSUSER=root
export INSROOT=/root
export INSNAME=IUKH
export INSDIR=$INSROOT/apprun/App/$INSNAME
export IZDIR=`dirname $0`

#mkdir and copy and cd
echo "Preparing application area"
rm -rf $INSROOT/apprun/App/$INSNAME
mkdir -p $INSROOT/apprun/App/$INSNAME
mkdir -p $INSROOT/apprun/Data/$INSNAME
#copy
cp $IZDIR/* $INSROOT/apprun/App/$INSNAME

cd $INSROOT

echo "Updating software lists"
apt -qq --assume-yes update
echo "Installing required additional system software"
apt -qq --assume-yes install mono-runtime
echo "Reverify"
apt -qq --assume-yes install mono-runtime

#what bridge will want
echo "Installing required additional system software"
apt -qq --assume-yes install openjdk-8-jdk
apt -qq --assume-yes install fswebcam alsa-utils miniupnpc motion zip unzip unattended-upgrades libav-tools
apt -qq --assume-yes install mpg123 shellinabox screen

echo "Second go to be sure"
apt -qq --assume-yes install openjdk-8-jdk
apt -qq --assume-yes install fswebcam alsa-utils miniupnpc motion zip unzip unattended-upgrades libav-tools
apt -qq --assume-yes install mpg123 shellinabox screen

cd apprun/App/$INSNAME

chmod +x *.sh

cd $INSROOT

mkdir tmp

echo "Disabling ipv6"
echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
cat tmp/scadd >> /etc/sysctl.conf

echo "Setting $INSNAME to start at boot"
echo "#!/bin/sh -e" > tmp/stadd
if [ -e "/etc/rc.local" ]
then
cat /etc/rc.local | grep -v "exit " | grep -v "startiuk.sh" | grep -v "#\!/bin" >> tmp/stadd
fi
echo "su $INSUSER -c \"$INSROOT/apprun/App/$INSNAME/startiuk.sh\"" >> tmp/stadd
echo "exit 0" >> tmp/stadd
cat tmp/stadd > /etc/rc.local

#chown
chown -R $INSUSER apprun
chown -R $INSUSER tmp

echo ""

echo "Starting IUKH"
./apprun/App/$INSNAME/startiuk.sh

echo ""

