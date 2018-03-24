#!/bin/bash

cd App

unzip -t KBridge.zip

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

unzip -o KBridge.zip

lae=$?;if [[ $lae -ne 0 ]]; then chmod +x KBridge/*.sh;exit $lae; fi

chmod +x KBridge/*.sh

sync

cd ..

./App/KBridge/postupgrade.sh

touch ./App/KBridge/upgradeDone.txt

sync
