#!/bin/bash

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

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -libraryName=$APPBLDNM -mainClass=App:AppStart -loadSyns=../beApp/lib/wa/jv/BEL_App.syn -loadIds=../beApp/lib/wa/jv/BEL_App -initLib=App --emitLang jv --emitFlag wajv --buildFile build/build.txt $BEBLDARGS

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../beBase/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

case "$una" in
  *Msys*)
    export CLASSPATH="../beApp/lib/wa/jv/*;../beBase/lib/ex/jv/*;extlibs/jv/*;../beApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="../beApp/lib/wa/jv/*:../beBase/lib/ex/jv/*:extlibs/jv/*:../beApp/extlibs/wa/jv/*"
    ;;
esac

javac $BEJVARGS ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

if [ -e build/buildbr.txt ]; then
  export CLASSPATH=../beBase/target5/*
  java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be $BRBLDARGS --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -libraryName=$APPBLDNM -loadSyns=../beApp/lib/wabr/js/BEL_App.syn -initLib=App -jsInclude=../beApp/lib/wabr/js/BEL_App.js --emitLang js --emitFlag wajv --ownProcess false --buildFile build/buildbr.txt
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv
jar -cf ../../../BEL_${APPBLDNM}_jv.jar .
cd ../../../../../../$APPBLDNM

cp ../beBase/lib/ex/jv/*.jar ../apprun/App/$APPBLDNM
cp ../beApp/lib/wa/jv/*.jar ../apprun/App/$APPBLDNM

if [ -e build/buildbr.txt ]; then
  cp ../apprun/App/$APPBLDNM/$APPBLDNM/target/js/be/BEL_${APPBLDNM}.js ../apprun/App/$APPBLDNM/BEX_E.js
fi
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../beApp/extlibs/wa/jv/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM
rm -rf ../apprun/App/$APPBLDNM/$APPBLDNM/target

#cd ../apprun/App/$APPBLDNM
