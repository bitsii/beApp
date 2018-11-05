#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

ARCHINFO="$(uname -a)"
if echo "$ARCHINFO" | grep -q "armv7"; then
    echo "MATCH ARM"
    DFNAME="domoticz_linux_armv7l.tgz"
fi
if echo "$ARCHINFO" | grep -q "x86_64"; then
    echo "MATCH x86"
    DFNAME="domoticz_linux_x86_64.tgz"
fi
if echo "$ARCHINFO" | grep -q "i686"; then
    echo "MATCH x86"
    DFNAME="domoticz_linux_x86_64.tgz"
fi

killall -w -u $USER domoticz

touch Data/KBridge/domoEnabled.txt

if [ ! -e ./Opt/Domo ]; then
  wget --tries=10 --retry-connrefused "https://releases.domoticz.com/releases/release/${DFNAME}"
  if [ -e "./${DFNAME}" ]; then
    mkdir -p ./Opt/Domo
    cd ./Opt/Domo
    tar -xzvf "../../${DFNAME}"
    rm -f "../../${DFNAME}"
    cd ../..
    #cp Data/KBridge/haproxy/cert.pem Opt/Domo/server_cert.pem
  fi
fi

./App/KBridge/startdomo.sh

echo ""

