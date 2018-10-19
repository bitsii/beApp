#!/bin/bash

export PATH=$PATH:.:/sbin:/usr/sbin

mkdir -p Data/KBridge/haproxy
mkdir -p $1

echo -n "1 " 
echo "$1"
echo -n "2 " 
echo "$2"

if [ ! -e "./Data/KBridge/haproxy/$2" ]; then
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com"
   cat cert.pem key.pem > all.pem
   rm cert.pem
   rm key.pem
   mv all.pem Data/KBridge/haproxy/$2
fi

haproxy -dV -D -p $1/haproxy.pid -f $1/haproxy.cfg -sf $(cat $1/haproxy.pid)

