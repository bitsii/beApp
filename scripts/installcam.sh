#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

if [ "$EUID" -eq 0 ]
  then echo "Please don't run as root run as user who the app will run as"
  exit
fi

export INSUSER="$USER"

export INSDIR=`echo $(getent passwd $INSUSER )| cut -d : -f 6`
export IZDIR=`dirname $0`

echo ""
echo "INSUSER $INSUSER"
echo "INSDIR $INSDIR"
echo "IZDIR $IZDIR"

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
cp ../KBridge/javax.servlet-api-*.jar .
cp ../KBridge/sqlite-jdbc-*.jar .
cp ../KBridge/jetty-all-*-uber.jar .

echo "Done getting software"

chmod +x *.sh

cd $INSDIR/apprun

echo "Done with installcam"

echo ""
