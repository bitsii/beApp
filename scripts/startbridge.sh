#!/bin/bash
export PATH=$PATH:.
(./App/KBridge/iuhcmdrs.sh --appType server 2>&1 | split -b 10485760 - /tmp/bapp$$.log) &
