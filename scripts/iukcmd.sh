#!/bin/bash

cd ~
cd apprun

mono --debug App/IUKH/BEX_E_mcs.exe --wpaSup /etc/wpa_supplicant/wpa_supplicant.conf --wpaRestart true --rmHostConfig true --hostConfig /boot/iukhost.conf --bridgePropFile /home/pi/insprops.sh --bridgeProp INIMAPSRV --bridgeProp INIMAPACCT --bridgeProp INIMAPPASS --bridgeProp INDNAME --bridgeProp DOUPNPFWD --wpaPostRestartPause 10 --bridgeInstallScript ./App/IUKH/dlbinstall.sh $*


