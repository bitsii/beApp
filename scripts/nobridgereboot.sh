#!/bin/bash
PSINFO="$(ps auwwwx)"
if echo "$PSINFO" | grep -q "App/KBridge/\*"; then
    echo "BRIDGE RUNNING"
else
    echo "BRIDGE NOT RUNNING"
    reboot
fi
