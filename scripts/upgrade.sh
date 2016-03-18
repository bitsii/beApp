#!/bin/bash

mkdir -p App/Dz.bak
rm -f App/Dz.bak/*
cp App/Dz/* App/Dz.bak
cd App/Dz
unzip -o ../Dz.zip
cd ../..
./App/Dz/postupgrade.sh
