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

echo "Please provide imap information for sharing connection information."
echo -n "Imap server: "
read inimapsrv
echo ""
echo -n "Imap account: "
read inimapacct
echo ""
echo -n "Imap Password: "
read -s inimappassword
echo ""
echo -n "Repeat Imap Password: "
read -s inimappassword2
echo ""

if [ "$inimappassword" != "$inimappassword2" ]; then
echo "Passwords don't match"
exit 1
fi

echo "export INIMAPSRV=\"$inimapsrv\"" >> $INSDIR/insprops.sh
echo "export INIMAPACCT=\"$inimapacct\"" >> $INSDIR/insprops.sh
echo "export INIMAPPASS=\"$inimappassword\"" >> $INSDIR/insprops.sh

chown $INSUSER $INSDIR/insprops.sh

$IZDIR/install.sh
