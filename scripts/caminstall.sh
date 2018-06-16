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
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.19.3/sqlite-jdbc-3.19.3.jar
wget --tries=10 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar

chmod +x *.sh

cd $INSDIR

if [ "$OSTYPE" == "Linux" ]; then
  #chown
  chown -R $INSUSER apprun
  chown -R $INSUSER tmp
fi

echo ""
