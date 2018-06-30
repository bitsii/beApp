#!/bin/bash

rm -f Data/KBridge/sshEnabled.txt

mkdir -p Data/KBridge/Apps
touch Data/KBridge/sshEnabled.txt

sudo systemctl enable ssh
sudo systemctl start ssh

echo ""

