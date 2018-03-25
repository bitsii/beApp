#!/bin/bash
export PATH=$PATH:.
cd && (./apprun/App/IUCam/iucrun.sh 2>&1 | split -b 10485760 - /tmp/iuc$$.dzlog) &
