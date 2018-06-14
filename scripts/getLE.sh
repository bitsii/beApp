#!/bin/bash

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd startLe

sleep 5

if [ "$1" == "getCert" ]; then

echo "cb get em $3 $2"
#sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email $3 -d $2

fi

if [ "$1" == "renewCert" ]; then

echo "cb ren"
sudo certbot -q renew --dry-run

fi

sleep 5

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd stopLe

rm -f fullchain.pem
rm -f privkey.pem
rm -f all.pem

sudo cp /etc/letsencrypt/live/$2/fullchain.pem .
sudo cp /etc/letsencrypt/live/$2/privkey.pem .

if [ -e "fullchain.pem" ] && [ -e "privkey.pem" ]; then

  cat fullchain.pem privkey.pem > all.pem

  rm -f Data/KBridge/haproxy/cert.pem.0
  mv Data/KBridge/haproxy/cert.pem Data/KBridge/haproxy/cert.pem.0
  mv all.pem Data/KBridge/haproxy/cert.pem

  rm -f fullchain.pem
  rm -f privkey.pem

  ./App/KBridge/starthap.sh

fi
