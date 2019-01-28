#!/bin/bash

export OSTYPE=`uname`

export IZDIR=`dirname $0`

if [ "$OSTYPE" == "Linux" ]; then

  if [ "$EUID" -eq 0 ]
    then echo "Please do not run setup as root, run as the user the service will run as."
    exit
  fi

  export INSUSER="$USER"

  export INSDIR=`echo $(getent passwd $INSUSER )| cut -d : -f 6`

fi

if [ "$OSTYPE" == "Darwin" ]; then

  export INSUSER="$USER"
  export INSDIR=`cd;pwd`

fi

#mkdir and copy and cd
echo "Preparing application area"
rm -rf $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/App/KBridge
mkdir -p $INSDIR/apprun/Data/KBridge
mkdir -p $INSDIR/apprun/logs
#copy
cp -r $IZDIR/* $INSDIR/apprun/App/KBridge

cd $INSDIR

cd apprun/App/KBridge

echo "Getting required additional application software"
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.19.3/sqlite-jdbc-3.19.3.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar

chmod +x *.sh

cd $INSDIR
mkdir -p apprun/tmp
