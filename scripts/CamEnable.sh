#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

killall -w -u $USER iuccmdrs.sh
kill `ps ax | grep java | grep -v grep | grep CamPlugin | awk '{$1=$1}1' | cut -d " " -f 1`

touch Data/KBridge/camEnabled.txt

if [ ! -e ./App/IUCam/iuccmdrs.sh ]; then
  rm -rf caminst
  mkdir -p caminst
  cd caminst
  wget --tries=10 --retry-connrefused https://bitbucket.org/abelii/edgii/downloads/IUCam.zip
  unzip IUCam.zip
  chmod +x IUCam/*.sh
  sleep 5
  ./IUCam/installcam.sh
  sleep 5
  cd ..
  rm -rf caminst
  rm -f IUCam.zip
fi

./App/KBridge/startcam.sh
