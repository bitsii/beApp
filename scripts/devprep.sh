#!/bin/bash

export OSTYPE=`uname`

if [[ "$OSTYPE" == *"MINGW"* ]]; then
  echo "Mswin"
  echo "Install wget for windows https://eternallybored.org/misc/wget/"
  echo "(add it to your path)"
  echo "Same for zip - http://gnuwin32.sourceforge.net/packages/zip.htm"
  echo "(need deps for zip too)"
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

mkdir -p extlibs/wa/jv
rm -f extlibs/wa/jv/*
cd extlibs/wa/jv

wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget --tries=20 --timeout 20 --retry-connrefused https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar

cd ../../..
