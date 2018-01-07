#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
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

chown $INSUSER $INSDIR/insprops.sh

$IZDIR/install.sh
