#!/bin/bash

rm -f Data/KBridge/sshEnabled.txt

sudo systemctl stop ssh
sudo systemctl disable ssh

echo ""

