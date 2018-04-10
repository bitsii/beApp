#!/bin/bash

cd /home/pi

nohup ./apprun/App/KBridge/iupohcmdrs.sh 2>&1 | split -b 10485760 - /tmp/iupoh$$.dzlog &      
