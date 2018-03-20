#!/bin/bash
export PATH=$PATH:.
cd && (./apprun/App/KBridge/iuhrun.sh 2>&1 | split -b 10485760 - /tmp/app$$.dzlog) &
