#!/bin/bash

(nohup ./App/KBridge/dupgsbk.sh $* 2>&1 | split -b 10485760 - /tmp/dupgs$$.log) &
