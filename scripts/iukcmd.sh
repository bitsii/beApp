#!/bin/bash

cd ~
cd apprun

mono --debug App/IUKH/BEX_E_mcs.exe --wpaSup /etc/wpa_supplicant/wpa_supplicant.conf --wpaRestart true --rmHostConfig true --hostConfig /boot/iukhost.conf --bridgeConfig /boot/iukbridge.conf --rmBridgeConfig true --bridgePropFile /home/pi/insprops.sh --bridgeProp INIMAPSRV --bridgeProp INIMAPACCT --bridgeProp INIMAPPASS --bridgeProp INDNAME --wpaPostRestartPause 10 --bridgeInstallScript ./App/IUKH/dlbinstall.sh $*


