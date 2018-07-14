#!/bin/bash

killall -w -u $USER iuncmdrs.sh
kill `ps ax | grep java | grep -v grep | grep KBNamePlugin | awk '{$1=$1}1' | cut -d " " -f 1`

mkdir -p Data/KBridge/Apps
touch Data/KBridge/dnsEnabled.txt

./App/KBridge/startiun.sh

sudo apt -qq --assume-yes update
sudo apt -qq --assume-yes install pdns-backend-remote

sudo cat /etc/powerdns/pdns.conf | grep -v launch= | grep -v remote-connection-string= | grep -v recursor= > pdns.conf

echo "launch=remote" >> pdns.conf
echo "remote-connection-string=http:url=http://127.0.0.1:6419,post=1,post_json=1" >> pdns.conf
cat rgw >> pdns.conf

rm -f rgw
sudo chown root:root pdns.conf
sudo chmod 600 pdns.conf
sudo mv pdns.conf /etc/powerdns

sudo service pdns restart
sleep 2
sudo service pdns restart


echo ""

