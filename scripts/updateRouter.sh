#!/bin/bash
sleep 20
cd && cd apprun && ( ./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd routerUpdate 2>logs/updr.err > logs/updr.out ) &
