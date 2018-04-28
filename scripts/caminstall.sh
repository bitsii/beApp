#!/bin/bash

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
export IZDIR=`dirname $0`

if [ $# -ge 2 ]; then
  inusername=$1
  inpassword=$2
else
  echo "Please provide initial account information, you'll need this to login and use the application."
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

fi

echo "export INUSR=\"$inusername\"" > $INSDIR/caminsprops.sh
echo "export INPASS=\"$inpassword\"" >> $INSDIR/caminsprops.sh

. $INSDIR/caminsprops.sh

#mkdir and copy and cd
echo "Preparing application area"
rm -rf $INSDIR/apprun/App/IUCam
mkdir -p $INSDIR/apprun/App/IUCam
mkdir -p $INSDIR/apprun/Data/IUCam
#copy
cp -r $IZDIR/* $INSDIR/apprun/App/IUCam

cd $INSDIR

cd apprun/App/IUCam

echo "Getting required additional application software"
wget --tries=10 --retry-connrefused https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.19.3/sqlite-jdbc-3.19.3.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar

chmod +x *.sh

cd $INSDIR

./apprun/App/IUCam/iuccmd.sh --appType cmd --confCmd saveLocalUrl --urlFile localCamUrl.txt

#create account

./apprun/App/IUCam/iuccmd.sh --appType cmd --authCmd putAccount --user $INUSR --pass $INPASS --perms admin

echo ""

./apprun/App/IUCam/startiuc.sh

echo "service is starting now, it may take a few moments to come up"
echo "the server url is below, you can copy and paste into a browser on the network"
echo "and then login with the account you specified during setup"
echo "setup the remote service in konnectii bridge to access outside local network"

cat $INSDIR/apprun/localCamUrl.txt

rm -f $INSDIR/caminsprops.sh

echo ""
