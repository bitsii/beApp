#!/bin/sh

rm -rf ../appinstaller
mkdir ../appinstaller
cp -f scripts/install.sh ../appinstaller
cd ..
cp IUBHub.zip appinstaller
./makeselfbin/makeself.sh --current appinstaller iubhinstall.run IUBHInstall ./install.sh
cd ioturl
