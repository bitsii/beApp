#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, try running the command 'sudo $0'"
  exit
fi

export INSUSER=pi
export INSDIR=/home/pi
export IZDIR=`dirname $0`

. $INSDIR/insprops.sh

#mkdir and copy and cd
echo "Preparing application area"
rm -rf $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/Data/KBridge
#copy
cp -r $IZDIR/* $INSDIR/apprun/App/KBridge

cd $INSDIR

echo "Updating software lists"
apt -qq --assume-yes update
echo "Installing required additional system software"
apt -qq --assume-yes install oracle-java8-jdk
apt -qq --assume-yes install fswebcam alsa-utils miniupnpc motion zip unzip unattended-upgrades libav-tools
apt -qq --assume-yes install mpg123 shellinabox screen

#python3-pip hass

cd apprun/App/KBridge

echo "Getting required additional application software"
wget --tries=10 --retry-connrefused https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.19.3/sqlite-jdbc-3.19.3.jar
wget --tries=10 --retry-connrefused https://github.com/javaee/javamail/releases/download/JAVAMAIL-1_5_6/javax.mail.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar

chmod +x *.sh

cd $INSDIR

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

#chown
chown -R $INSUSER apprun
chown -R $INSUSER tmp

su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --hubCmd saveLocalUrl --urlFile localUrl.txt"

#create account

su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin"

echo ""

su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --confCmd putConfig --key deviceName --value $INDNAME"

echo ""

su $INSUSER -c "./apprun/App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerLink --auser $INUSR --konUser $KONUSER --konPass $KONPASS"        
        
echo ""

su $INSUSER -c "./apprun/App/KBridge/startiuh.sh"

echo "service is starting now, it may take a few moments to come up"
echo "the server url is below, you can copy and paste into a browser on the network"
echo "and then login with the account you specified during setup"

cat $INSDIR/apprun/localUrl.txt

rm -f $INSDIR/insprops.sh

echo ""

