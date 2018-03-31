#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, try running the command 'sudo $0'"
  exit
fi

export INSUSER=pi
export INSDIR=/home/pi
export IZDIR=`dirname $0`

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

echo "export INUSR=\"$inusername\"" > $INSDIR/insprops.sh
echo "export INPASS=\"$inpassword\"" >> $INSDIR/insprops.sh

echo "Please provide a short, friendly name for the device."
echo -n "DeviceName: "
read indname
echo ""
echo "export INDNAME=\"$indname\"" >> $INSDIR/insprops.sh

echo "Do you want to expose to the internet using UPnP port forwarding from your home router?"
echo -n "Do UPnP Forward, enter true or false: "
read doupnpfwd
echo ""
echo "export DOUPNPFWD=\"$doupnpfwd\"" >> $INSDIR/insprops.sh

echo "Do you want to expose device to the internet via a remote host?"
echo "Configure remote access via remote host (ssh port forward)"
echo -n "enter true or false: "
read dossh
echo ""
if [ "$dossh" == "true" ]; then
  echo "Please provide ssh info"
  echo -n "ssh host: "
  read shost
  echo ""
  echo -n "ssh username: "
  read suser
  echo ""
  
  echo -n "ssh Password: "
  read -s sinpassword
  echo ""
  echo -n "Repeat ssh Password: "
  read -s sinpassword2
  echo ""

  if [ "$sinpassword" != "$sinpassword2" ]; then
  echo "Passwords don't match"
  exit 1
  fi
  
  echo "export SHOST=\"$shost\"" >> $INSDIR/insprops.sh
  echo "export SUSER=\"$suser\"" >> $INSDIR/insprops.sh
  echo "export SPASS=\"$sinpassword\"" >> $INSDIR/insprops.sh
fi

chown $INSUSER $INSDIR/insprops.sh

$IZDIR/bridgesetup.sh
