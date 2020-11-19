#!/bin/bash

export OSTYPE=`uname`

if [[ "$OSTYPE" == *"MINGW"* ]]; then
  echo "Mswin"
fi

if [ "$OSTYPE" == "Linux" ]; then
  echo "Linux"
  sudo apt-get install makeself
  sudo apt-get install node-uglify
fi

if [ "$OSTYPE" == "Darwin" ]; then
  echo "Macos"
  brew install makeself
fi
