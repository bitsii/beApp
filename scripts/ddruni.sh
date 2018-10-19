#!/bin/bash

mkdir -p ./Data/KBridge/ddclient

rm -f ./Data/KBridge/ddclient/ddclienti.cache

#./App/KBridge/ddclient -debug -verbose -noquiet -file ./Data/KBridge/ddclient/ddclient.conf -cache ./Data/KBridge/ddclient/ddclient.cache

./App/KBridge/ddclient -file ./Data/KBridge/ddclient/ddclienti.conf -cache ./Data/KBridge/ddclient/ddclienti.cache
