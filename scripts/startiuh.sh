#!/bin/bash
export PATH=$PATH:.
cd /home/pi && (./apprun/App/IUHub/iuhrun.sh 2>&1 | split -b 10485760 - /tmp/app$$.dzlog) &
