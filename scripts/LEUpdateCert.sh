#!/bin/bash

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd startLe

sleep 25

sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email $2 -d $1

sleep 5

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd stopLe

rm -f fullchain.pem
rm -f privkey.pem
rm -f all.pem

sudo cp /etc/letsencrypt/live/$1/fullchain.pem .
sudo cp /etc/letsencrypt/live/$1/privkey.pem .

cat fullchain.pem privkey.pem > all.pem

rm -f Data/KBridge/haproxy/cert.pem.0
mv Data/KBridge/haproxy/cert.pem Data/KBridge/haproxy/cert.pem.0
mv all.pem Data/KBridge/haproxy/cert.pem

rm -f fullchain.pem
rm -f privkey.pem

./App/KBridge/starthap.sh
