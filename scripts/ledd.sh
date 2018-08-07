#!/bin/bash

export DUCKDNS_TOKEN="$2"
lego -a --email="$1" --domains="$3" --dns duckdns -a run

cd .lego/certificates

if [ -e "$3.crt" ] && [ -e "$3.key" ]; then
  cat "$3.crt" "$3.key" > all.pem
  mv all.pem ../../Data/KBridge/haproxy/cert.pem
fi

cd ../..

./App/KBridge/distcert.sh
