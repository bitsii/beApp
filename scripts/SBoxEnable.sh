#!/bin/bash

rm -f Data/KBridge/sboxEnabled.txt

mkdir -p Data/KBridge/Apps
touch Data/KBridge/sboxEnabled.txt

sudo apt -qq --assume-yes update
sudo apt -qq --assume-yes install shellinabox

echo ""

