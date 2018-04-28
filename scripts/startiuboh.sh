#!/bin/bash

cd $HOME

if [ -e "./openhab/start.sh" ]; then
   screen -dmS test bash -c '$HOME/openhab/start.sh 2>/tmp/oherr >/tmp/ohout'
   ./apprun/App/KBridge/startiupoh.sh
fi
