#!/bin/bash
export PATH=$PATH:.
cd && (./apprun/App/IUHub/iuhrun.sh lwui 2>&1 | split -b 10485760 - /tmp/app$$.dzlog) &
