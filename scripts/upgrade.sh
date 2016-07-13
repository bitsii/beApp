#!/bin/bash

echo `pwd` > /tmp/upgrade.out

./App/IUHub/upgrade2.sh 2>/tmp/upgrade.err >>/tmp/upgrade.out
