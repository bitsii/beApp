#!/bin/bash

sleep 2

mkdir -p App/Dz.bak
rm -f App/Dz.bak/*
cp App/Dz/* App/Dz.bak
cd App/Dz

unzip -t ../Dz.zip

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

unzip -o ../Dz.zip
chmod +x *.sh

cd ../..
sleep 1
./App/Dz/postupgrade.sh
sleep 1
