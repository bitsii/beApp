#!/bin/bash

echo `pwd` > /tmp/upgrade.out

chmod +x ./App/KBridge/*.sh

./App/KBridge/upgrade2.sh 2>/tmp/upgrade.err >/tmp/upgrade.out
