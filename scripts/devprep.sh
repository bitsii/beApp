#!/bin/bash

export OSTYPE=`uname`

if [[ "$OSTYPE" == *"MINGW"* ]]; then
  echo "Mswin"
  echo "Install wget for windows http://gnuwin32.sourceforge.net/packages/wget.htm"
  echo "(add it to your path)"
  npm -g install uglify-js
fi

if [ "$OSTYPE" == "Linux" ]; then
  echo "Linux"
  sudo apt-get install curl
  sudo apt-get install makeself
  sudo apt-get install node-uglify
fi

if [ "$OSTYPE" == "Darwin" ]; then
  echo "Macos"
  brew install wget
  brew install makeself
  npm -g install uglify-js
fi
