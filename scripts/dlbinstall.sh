#!/bin/bash

cd ~

mkdir -p INSBR

cd INSBR

rm -f IUBHub.zip


until unzip -o IUBHub.zip; do
  until wget https://bitbucket.org/ioturl/ioturl/downloads/IUBHub.zip; do
    sleep 10
  done
  sleep 10
done


chmod +x ./IUHub/*.sh

./IUHub/install.sh

