#!/bin/bash

. ../beBase/scripts/bld5ext.sh

export APPBLDNM=${PWD##*/}

export OSTYPE=`uname`

if [ "$OSTYPE" == "Darwin" ]; then
  export BLDPLAT="macos"
fi

if [ "$OSTYPE" == "Linux" ]; then
  export BLDPLAT="linux"
fi

if [[ $OSTYPE == *"MINGW"* ]]; then
  export BLDPLAT="mswin"
fi

if [ "$BERCDONE" != "true" ]; then
  if [ -e "./build/build${BLDPLAT}rcjv.sh" ]; then
    . "./build/build${BLDPLAT}rcjv.sh"
  fi
fi

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../beApp/scripts/runwajv.sh ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM
cp ../beApp/scripts/stopwajvrs.sh ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwajv.bat ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwajvex.bat ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwajvrs.bat ../apprun/App/$APPBLDNM
cp ../beApp/scripts/runwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../beApp/scripts/stopwajvrs.bat ../apprun/App/$APPBLDNM
cp ../beApp/scripts/stopwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../beApp/scripts/stopwajv.bat ../apprun/App/$APPBLDNM
cp ../beApp/scripts/stopwajv.vbs ../apprun/App/$APPBLDNM

una=`uname -a`

if [ ! -z "$BERCME" -a "$BERCME" != " " ]; then
  if [ -e "$BERCME" ]; then
    . "$BERCME"
  fi
fi

if [ ! -z "$BEPREBUILD" -a "$BEPREBUILD" != " " ]; then
  eval "$BEPREBUILD"
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

$BEBLDR ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -mainClass=App:AppStart --emitLang jv --emitFlag wajv --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/AppEUI.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/WebServer.be ../beApp/source/WebApp.be ../beApp/source/Db.be ../beApp/source/MFSKvDb.be

#java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../beBase/source/extended/Log.be ../beBase/source/extended/LogSink.be ../beApp/source/App.be ../beApp/source/BrowserUI.be ../beApp/source/BrowserJvFx.be ../beApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../beBase/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

case "$una" in
  *Msys*)
    export CLASSPATH="../beBase/target5/*;extlibs/jv/*;../beApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="../beBase/target5/*:extlibs/jv/*:../beApp/extlibs/wa/jv/*"
    ;;
esac

cp ../beBase/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be

javac $BEJVARGS ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

if [ -e build/buildbr.txt ]; then
  $BEBLDR ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt $BRBLDARGS --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --emitFlag wajv --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/AppEUI.be ../beApp/source/BrowserEUI.be
fi

#java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../beBase/source/extended/Log.be ../beApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/Base/target/jv
jar -cf ../../../BEL_Base_jv.jar .
cd ../../../../../../$APPBLDNM

if [ -e build/buildbr.txt ]; then
  cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js ../apprun/App/$APPBLDNM/BEX_E.js
fi
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../beApp/extlibs/wa/jv/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM
rm -rf ../apprun/App/$APPBLDNM/Base/target

#cd ../apprun/App/$APPBLDNM
