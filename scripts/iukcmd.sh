#!/bin/bash

cd ~
cd apprun

mono --debug App/IUKH/BEX_E_mcs.exe --wpaSup /etc/wpa_supplicant/wpa_supplicant.conf --wpaRestart true --rmHostConfig true --hostConfig /boot/iukhost.conf --bridgePropFile /home/pi/insprops.sh --bridgeProp INUSR --bridgeProp INPASS --bridgeProp DDOMAIN --bridgeProp DTOKEN --bridgeProp SHOST --bridgeProp SUSER --bridgeProp SPASS --bridgeProp INDNAME --bridgeProp DOUPNPFWD --bridgeProp HPORTLOC --bridgeProp HPORTEXT --wpaPostRestartPause 10 --bridgeInstallScript ./App/IUKH/dlbinstall.sh $*

