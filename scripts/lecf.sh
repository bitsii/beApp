#!/bin/bash

#is 60 days renewcheck -mmin works for mins, -mtime for days, +N
#-mtime +60 -mmin +10

ARCHINFO="$(uname -a)"
if echo "$ARCHINFO" | grep -q "armv7"; then
    echo "MATCH ARM"
    lcmd="./App/KBridge/lego_arm7"
fi
if echo "$ARCHINFO" | grep -q "x86_64"; then
    echo "MATCH x86"
    lcmd="./App/KBridge/lego_x86"
fi
if echo "$ARCHINFO" | grep -q "i686"; then
    echo "MATCH x86"
    lcmd="./App/KBridge/lego_x86"
fi

export certf=".lego/certificates/$3.crt"
found="no"
if [ "$4" == "renew" ]; then
  if [[ $(find "$certf" -mtime +60 -print) ]]; then
    found="yes"
  fi
  if [ "$found" == "no" ]; then
    echo "Not renewing, not old"
    exit
  fi
fi

export CLOUDFLARE_EMAIL="$1"
export CLOUDFLARE_API_KEY="$2"
$lcmd -a --email="$1" --domains="$3" --dns cloudflare "$4"
#./App/KBridge/lego

cd .lego/certificates

if [ -e "$3.crt" ] && [ -e "$3.key" ]; then
  cat "$3.crt" "$3.key" > all.pem
  mv all.pem ../../Data/KBridge/haproxy/$5
fi

cd ../..

./App/KBridge/restarthaps.sh
