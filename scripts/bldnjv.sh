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

rm -rf njv
mkdir -p njv

cp ../beApp/scripts/runnjv.sh njv

una=`uname -a`

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../beBase/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be --buildFile ../beApp/build/base.txt --buildFile ../beApp/build/extended.txt --buildFile build/njv.txt --deployPath njv --buildPath njv --emitLang jv ../beBase/source/extended/Log.be $*

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../beApp/lib/wa/jv/*;../beBase/lib/ex/jv/*;extlibs/jv/*;../beApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="../beApp/lib/wa/jv/*:../beBase/lib/ex/jv/*:extlibs/jv/*:../beApp/extlibs/wa/jv/*"
    ;;
esac

javac $BEJVARGS ./njv/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ./njv/Base/target/jv
jar -cf ../../../BEL_${APPBLDNM}_jv.jar .
cd ../../../../

cd ../beBase/system/jv
jar -cf ../../../${APPBLDNM}/njv/BEL_system_be_jv.jar .
cd ../../../${APPBLDNM}

#cp ../beBase/lib/ex/jv/*.jar ./njv
#cp ../beApp/lib/wa/jv/*.jar ./njv

#cp ../beApp/extlibs/wa/jv/* ./njv
#cp extlibs/jv/* ./njv
rm -rf ./njv/Base
