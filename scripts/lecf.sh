#!/bin/bash

export CLOUDFLARE_EMAIL="$1"
export CLOUDFLARE_API_KEY="$2"
lego -a --email="$1" --domains="$3" --dns cloudflare -a run

cd .lego/certificates

if [ -e "$3.crt" ] && [ -e "$3.key" ]; then
  cat "$3.crt" "$3.key" > all.pem
  mv all.pem ../../Data/KBridge/haproxy/cert.pem
fi

cd ../..

./App/KBridge/distcert.sh
