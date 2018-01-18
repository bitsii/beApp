#!/bin/bash
export PATH=$PATH:.
cd && (./apprun/App/IUKH/iukrun.sh 2>&1 | split -b 10485760 - /tmp/iuk$$.dzlog) &
