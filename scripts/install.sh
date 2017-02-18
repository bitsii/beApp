#!/bin/bash

killall startiuh.sh 2>/dev/null
killall iuhcmdrs.sh 2>/dev/null
killall java 2>/dev/null

cd

echo "Updating software lists"
sudo apt -qq --assume-yes update
echo "Installing required additional system software"
sudo apt -qq --assume-yes install fswebcam alsa-utils miniupnpc motion zip unzip unattended-upgrades libav-tools
sudo apt -qq --assume-yes install mpg123

echo "Preparing application area"
rm -rf apprun/App/IUHub
mkdir -p apprun/App/IUHub
cd apprun/App/IUHub

echo "Getting required additional application software"
wget https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar
wget https://java.net/projects/javamail/downloads/download/javax.mail.jar
wget https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar
wget https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar

#wget distro

unzip -o ../../../IUBHub.zip
chmod +x *.sh

cd
mkdir tmp

echo "Disabling ipv6"
echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
sudo -- sh -c 'cat tmp/scadd >> /etc/sysctl.conf'


echo "Setting IUHub to start at boot"
echo "#!/bin/sh -e" > tmp/stadd
echo "#" >> tmp/stadd
echo "# rc.local" >> tmp/stadd
echo "su $USER -c \"$HOME/apprun/App/IUHub/startiuh.sh\"" >> tmp/stadd
echo "exit 0" >> tmp/stadd
sudo -- sh -c 'cat tmp/stadd > /etc/rc.local'

./apprun/App/IUHub/startiuhlw.sh
