#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

./App/KBridge/stophaps.sh

if [ -e "./Data/KBridge/haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh ./Data/KBridge/haproxy cert.pem
fi

if [ -e "./Data/KBridge/int.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh ./Data/KBridge/int.haproxy certi.pem
fi

if [ -e "./Data/KBridge/Nxc.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/Nxc.haproxy cert.pem
fi

if [ -e "./Data/KBridge/webApp.Nxc.int.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Nxc.int.haproxy certi.pem
fi

if [ -e "./Data/KBridge/webApp.Cam.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Cam.haproxy cert.pem
fi

if [ -e "./Data/KBridge/webApp.Cam.int.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Cam.int.haproxy certi.pem
fi

if [ -e "./Data/KBridge/webApp.Domo.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Domo.haproxy cert.pem
fi

if [ -e "./Data/KBridge/webApp.Domo.int.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Domo.int.haproxy certi.pem
fi
