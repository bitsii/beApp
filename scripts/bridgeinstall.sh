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

echo "Please provide initial account information, you'll need this to login to"
echo "Konnectii Bridge after install.  This is not yet your Konnectii site login, this is the one"
echo "You want to use to login to the bridge on this host or device (they can be the same, but do not have to be)"
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

echo "Please provide a short, friendly name for the host or device."
echo -n "DeviceName: "
read indname
echo ""
echo "export INDNAME=\"$indname\"" >> $INSDIR/insprops.sh

echo "Link bridge to Konnectii to locate and login to bridge on the local network"
echo "and the Internet from https://www.konnectii.com.  Enter the username and password"
echo "you registered on the site - if you have not yet registered an account there pls do so now..."
echo -n "Konnectii username: "
read konuser
echo ""
echo -n "Konnectii Password: "
read -s konpass
echo ""
  
echo "export KONUSER=\"$konuser\"" >> $INSDIR/insprops.sh
echo "export KONPASS=\"$konpass\"" >> $INSDIR/insprops.sh

echo "Are you installing this on a host directly on the public internet or a device on your"
echo "home, office, or other private network?"
echo -n "Installing on private network? y or n: "
read privatenet

echo "export PRIVATENET=\"$privatenet\"" >> $INSDIR/insprops.sh

chown $INSUSER $INSDIR/insprops.sh

$IZDIR/bridgesetup.sh
