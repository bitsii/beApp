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

./apprun/App/IUHub/iuhcmd.sh --appType cmd --hubCmd saveLocalUrl --urlFile localUrl.txt

#create account

echo "Now create an account, you'll need this to login and use the application."
echo -n "Username: "
read inusername
echo ""
echo -n "Password: "
read inpassword

./apprun/App/IUHub/iuhcmd.sh --appType cmd --authCmd putAccount --user $inusername --pass $inpassword --perms admin

echo ""

./apprun/App/IUHub/startiuh.sh

echo "Waiting for the server to start for the first time, this can take awhile.  Please wait until the below message indicates the server is ready."
echo "Note, the certificate is self signed and you will need to accept it permanently once on each device you use to connect to this server."
sleep 40
echo "Server should now be ready"
echo "Navigate to the following url from any browser on the wifi network and login with the account you created"
echo "to complete setup"

cat ../apprun/localUrl.txt

echo ""

