#!/bin/bash

if [ -e "./Data/KBridge/haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh ./Data/KBridge/haproxy cert.pem
fi

if [ -e "./Data/KBridge/Nxc.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/Nxc.haproxy cert.pem
fi

if [ -e "./Data/KBridge/webApp.Cam.haproxy/haproxy.cfg" ]; then
  ./App/KBridge/starthap.sh Data/KBridge/webApp.Cam.haproxy cert.pem
fi

if [ -e "./Opt/Domo/server_cert.pem" ]; then
  killall -w -u $USER domoticz
  cp ./Data/KBridge/haproxy/cert.pem ./Opt/Domo/server_cert.pem
  ./App/KBridge/startdomo.sh
fi
