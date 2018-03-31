#!/bin/bash

screen -dmS test bash -c '/home/pi/apprun/App/KBridge/startohinner.sh 2>&1 | split -b 10485760 - /tmp/app$$.dzlog'

