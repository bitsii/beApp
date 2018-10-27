#!/bin/bash

export USER=`whoami`
export PATH=$PATH:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:.

killall -w -u $USER haproxy
