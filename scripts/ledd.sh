#!/bin/bash

#is 60 days renewcheck -mmin works for mins, -mtime for days, +N
#-mtime +60 -mmin +10

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

export DUCKDNS_TOKEN="$2"
lego -a --email="$1" --domains="$3" --dns duckdns "$4"

cd .lego/certificates

if [ -e "$3.crt" ] && [ -e "$3.key" ]; then
  cat "$3.crt" "$3.key" > all.pem
  mv all.pem ../../Data/KBridge/haproxy/cert.pem
fi

cd ../..

./App/KBridge/distcert.sh
