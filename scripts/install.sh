#!/bin/bash

cd

sudo apt -qq --assume-yes update
sudo apt -qq --assume-yes install fswebcam alsa-utils miniupnpc motion zip unzip unattended-upgrades libav-tools

mkdir -p apprun/App/IUHub
cd apprun/App/IUHub

wget https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar
wget https://java.net/projects/javamail/downloads/download/javax.mail.jar
wget https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar

#wget distro

unzip -o ../../../IUBHub.zip
chmod +x *.sh

cd
mkdir tmp

echo "net.ipv6.conf.all.disable_ipv6 = 1" > tmp/scadd
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> tmp/scadd
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> tmp/scadd
sudo -- sh -c 'cat tmp/scadd >> /etc/sysctl.conf'

echo "su pi -c \"/home/pi/apprun/App/IUHub/startiuh.sh\"" > tmp/stadd
echo "exit 0" >> tmp/stadd
sudo -- sh -c 'cat tmp/stadd > /etc/rc.local'

./apprun/App/IUHub/createAdminAccount.sh

./admin/App/IUHub/iuhcmd.sh cmd saveIntUrl shu.txt opu.sh

./apprun/App/IUHub/startiuh.sh

echo -n "To get started, you can open the following url on a browser from a device on the same network as this server and login with the account you just created - "
cat ./apprun/shu.txt
echo
echo "Note, the certificate is self signed and you will need to accept it permanently once on each device you use to connect to this server.  If you are asked to accept it in the same browser after adding permanently be careful, it may indicate a security issue.  If in doubt verify the certificate thumbprint for the site in your browser against the one in email before entering your username and password"
echo "Now opening a browser on this box to the url above, to continue, login with the account you just created"

chmod +x ./apprun/opu.sh
./apprun/opu.sh
