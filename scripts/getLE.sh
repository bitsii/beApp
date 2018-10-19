#!/bin/bash

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd startLe

sleep 25

if [ "$1" == "getCert" ]; then

echo "cb get em $2 $3"
sudo certbot certonly --agree-tos --email $2 --webroot -w /var/www/html/ -d $3

fi

if [ "$1" == "renewCert" ]; then

echo "cb ren"
sudo certbot -q renew

fi

sleep 5

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd stopLe

rm -f fullchain.pem
rm -f privkey.pem
rm -f all.pem

sudo cp /etc/letsencrypt/live/$3/fullchain.pem .
sudo cp /etc/letsencrypt/live/$3/privkey.pem .

if [ -e "fullchain.pem" ] && [ -e "privkey.pem" ]; then

  cat fullchain.pem privkey.pem > all.pem

  rm -f Data/KBridge/haproxy/cert.pem.0
  mv Data/KBridge/haproxy/cert.pem Data/KBridge/haproxy/cert.pem.0
  mv all.pem Data/KBridge/haproxy/cert.pem

  rm -f fullchain.pem
  rm -f privkey.pem

  ./App/KBridge/starthap.sh Data/KBridge/haproxy cert.pem
  
  if [ -e Opt/Domo/server_cert.pem ]; then
    rm -f Opt/Domo/server_cert.pem
    cp Data/KBridge/haproxy/cert.pem Opt/Domo/server_cert.pem
  fi

fi
