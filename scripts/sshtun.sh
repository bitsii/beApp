#!/bin/bash

sshpass -p $2 ssh -C -o TCPKeepAlive=yes -o ServerAliveInterval=10 $2@$1 -R $4

