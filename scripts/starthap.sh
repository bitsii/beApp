#!/bin/bash

mkdir -p Data/KBridge/haproxy

haproxy -D -p Data/KBridge/haproxy/haproxy.pid -f Data/KBridge/haproxy/haproxy.cfg -sf $(cat Data/KBridge/haproxy/haproxy.pid)

