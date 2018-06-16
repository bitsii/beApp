#!/bin/bash

mkdir -p Data/KBridge/haproxy
mkdir -p $1

if [ ! -e "./Data/KBridge/haproxy/cert.pem" ]; then
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com"
   cat cert.pem key.pem > all.pem
   rm cert.pem
   rm key.pem
   mv all.pem Data/KBridge/haproxy/cert.pem
fi

haproxy -dV -D -p $1/haproxy.pid -f $1/haproxy.cfg -sf $(cat $1/haproxy.pid)

