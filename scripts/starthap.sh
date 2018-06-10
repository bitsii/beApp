#!/bin/bash

mkdir -p Data/KBridge/haproxy

if [ ! -e "./Data/KBridge/haproxy/cert.pem" ]; then
   openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=www.example.com"
   cat cert.pem key.pem > all.pem
   rm cert.pem
   rm key.pem
   mv all.pem Data/KBridge/haproxy/cert.pem
fi

haproxy -dV -D -p Data/KBridge/haproxy/haproxy.pid -f Data/KBridge/haproxy/haproxy.cfg -sf $(cat Data/KBridge/haproxy/haproxy.pid)

