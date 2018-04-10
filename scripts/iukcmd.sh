#!/bin/bash

cd ~
cd apprun

mono --debug App/IUKH/BEX_E_mcs.exe --wpaSup /etc/wpa_supplicant/wpa_supplicant.conf --wpaRestart true --rmHostConfig true --hostConfig /boot/iukhost.conf --bridgePropFile /home/pi/insprops.sh --bridgeProp INUSR --bridgeProp INPASS --bridgeProp INDNAME --bridgeProp KONUSER --bridgeProp KONPASS --wpaPostRestartPause 10 --bridgeInstallScript ./App/IUKH/dlbinstall.sh $*

