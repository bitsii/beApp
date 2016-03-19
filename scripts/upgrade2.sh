#!/bin/bash

sleep 2

mkdir -p App/Dz.bak
rm -f App/Dz.bak/*
cp App/Dz/* App/Dz.bak
cd App/Dz
tar -xzvf ../Dz.tgz

cd ../..
sleep 1
./App/Dz/postupgrade.sh
sleep 1
