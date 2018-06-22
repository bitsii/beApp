#!/bin/bash

killall -w -u $USER iuccmdrs.sh
kill `ps ax | grep java | grep -v grep | grep CamPlugin | awk '{$1=$1}1' | cut -d " " -f 1`

mkdir -p Data/KBridge/Apps
touch Data/KBridge/camEnabled.txt

if [ ! -e ./App/IUCam/iuccmdrs.sh ]; then
  rm -rf caminst
  mkdir -p caminst
  cd caminst
  wget --tries=10 --retry-connrefused https://bitbucket.org/ioturl/ioturl/downloads/IUCam.zip
  unzip IUCam.zip
  chmod +x IUCam/*.sh
  sleep 5
  ./IUCam/installcam.sh
  sleep 5
  cd ..
  rm -rf caminst
  rm -f IUCam.zip
fi

(./App/IUCam/iuccmdrs.sh --appType server 2>&1 | split -b 10485760 - /tmp/capp$$.log) &

echo ""

