#!/bin/bash

cd ~
cd apprun

#loop/restart here

until ./App/IUKH/iukcmd.sh --runForever true; do
  sleep 10
done
