#!/bin/bash

mkdir -p ./Data/KBridge/ddclient

rm -f ./Data/KBridge/ddclient/ddclient.cache

./App/KBridge/ddclient -file ./Data/KBridge/ddclient/ddclient.conf -cache ./Data/KBridge/ddclient/ddclient.cache
