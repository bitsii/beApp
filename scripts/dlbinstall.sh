#!/bin/bash

cd ~

mkdir -p INSBR

cd INSBR

rm -f KBridge.zip


until unzip -o KBridge.zip; do
  until wget https://bitbucket.org/abelii/edgii/downloads/KBridge.zip; do
    sleep 10
  done
  sleep 10
done


chmod +x ./KBridge/*.sh

./KBridge/bridgesetup.sh

