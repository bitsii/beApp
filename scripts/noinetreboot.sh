#!/bin/sh

( ! ping -c1 google.com >/dev/null 2>&1 ) && echo "no inet restarting" && reboot
