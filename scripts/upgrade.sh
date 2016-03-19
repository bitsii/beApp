#!/bin/bash

mkdir -p App/Dz.bak
rm -f App/Dz.bak/*
cp App/Dz/* App/Dz.bak
cd App/Dz
tar -xzvf ../Dz.tgz

cd ../..
./App/Dz/postupgrade.sh
