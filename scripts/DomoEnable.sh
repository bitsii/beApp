#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

killall -w -u $USER domoticz

touch Data/KBridge/domoEnabled.txt

if [ ! -e ./Opt/Domo ]; then
  wget --tries=10 --retry-connrefused https://releases.domoticz.com/releases/release/domoticz_linux_armv7l.tgz
  if [ -e ./domoticz_linux_armv7l.tgz ]; then
    mkdir -p ./Opt/Domo
    cd ./Opt/Domo
    tar -xzvf ../../domoticz_linux_armv7l.tgz
    rm -f ../../domoticz_linux_armv7l.tgz
    cd ../..
    #cp Data/KBridge/haproxy/cert.pem Opt/Domo/server_cert.pem
  fi
fi

./App/KBridge/startdomo.sh

echo ""

