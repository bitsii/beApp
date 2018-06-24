#!/bin/bash

export OSTYPE=`uname`

export IZDIR=`dirname $0`

if [ "$OSTYPE" == "Linux" ]; then
  if [ "$EUID" -eq 0 ]
    then echo "Please do not run setup as root, run as the user the service will run as."
    exit
  fi
fi

echo ""
echo "Welcome to Edgii installation.  If you make a mistake hit Ctrl-C to halt"
echo "and then rerun the script to restart"
echo "" 
echo "Would you like to complete your setup in your web browser or do you prefer to complete setup" 
echo "in the terminal / via the text interface?"
echo "choose b for local browser setup (if you are logged into a graphical user interface on the"
echo "device you are setting up), n to receive a web address to complete setup using a browser on a different"
echo "device on the same network, or t to continue with a text/terminal setup."
echo -n "please enter b, n, or t (followed by enter key): "
read inbort

if [ "$inbort" == "b" ]; then
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --hubCmd assurePorts"
  bash -c "./App/KBridge/startball.sh"
  sleep 5
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --hubCmd initialSetup"
  exit 0
elif [ "$inbort" == "n" ]; then
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --hubCmd assurePorts"
  bash -c "./App/KBridge/startball.sh"
  sleep 5
  bash -c "./App/KBridge/iuhcmd.sh --appType cmd --hubCmd initialRemoteSetup"
  exit 0
fi

echo "Are you installing on a host on a private network (in a home or office) or "
echo "on a host directly on the internet (vps, cloud, etc)?"
echo -n "y for private network, n for directly on internet: "
read inprivatenet
echo ""

export PRIVATENET="$inprivatenet"

echo "Please provide desired username and password.  You'll need this to login to"
echo "Edgii Bridge after install.  This is not yet your Edgii site login," 
echo "this is the one you want to use to login on this device"
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

export INUSR="$inusername"
export INPASS="$inpassword"

echo "Please provide a unique name for the device."
echo "(unique among your devices...)"
echo -n "DeviceName: "
read indname
echo ""
export INDNAME="$indname"

echo "Link bridge to Edgii Router to locate and login to bridge on the local network"
echo "and the Internet from https://www.edgii.io.  Enter the username and password"
echo "you registered on the site - if you have not yet registered an account there pls do so now..."
echo -n "Edgii username: "
read konuser
echo ""
echo -n "Edgii Password: "
read -s konpass
echo ""
  
export KONUSER="$konuser"
export KONPASS="$konpass"

$IZDIR/setupbridge2.sh

echo "service is starting now, it may take a few moments to come up"
echo "On the Konnecti site, https://www.edgii.io, login to your account"
echo "and click the link to your new install under the name you provided.  Then you may login"
echo "using the account you just created during installation"

echo ""
