#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, try running the command 'sudo $0'"
  exit
fi

export INSUSER=pi
export INSDIR=/home/pi
export IZDIR=`dirname $0`

echo "Please provide initial account information, you'll need this to login to"
echo "Konnectii Bridge after install"
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

echo "Link bridge to Konnectii to locate and login to bridge on the local network"
echo "and the Internet https://konnectii.com"
echo -n "Konnectii username: "
read konuser
echo ""
echo -n "Konnectii Password: "
read -s konpass
echo ""
  
echo "export KONUSER=\"$konuser\"" >> $INSDIR/insprops.sh
echo "export KONPASS=\"$konpass\"" >> $INSDIR/insprops.sh

chown $INSUSER $INSDIR/insprops.sh

$IZDIR/bridgesetup.sh
