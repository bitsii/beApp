#!/bin/bash

sleep 2

mkdir -p App/IUHub.bak
rm -f App/IUHub.bak/*
cp App/IUHub/* App/IUHub.bak
cd App/IUHub

unzip -t ../IUHub.zip

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ..
unzip -o IUHub.zip
cd IUHub
chmod +x *.sh

cd ../..
sleep 1
./App/IUHub/postupgrade.sh
sleep 1
