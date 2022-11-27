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

cp ../braceApp/scripts/runnjv.sh njv

una=`uname -a`

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

export CLASSPATH=../brace/target5/*
java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --buildFile ../braceApp/build/extended.txt --buildFile build/njv.txt --deployPath njv --buildPath njv --emitLang jv ../brace/source/extended/Log.be $*

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../braceApp/lib/wa/jv/*;../brace/lib/ex/jv/*;extlibs/jv/*;../braceApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="../braceApp/lib/wa/jv/*:../brace/lib/ex/jv/*:extlibs/jv/*:../braceApp/extlibs/wa/jv/*"
    ;;
esac

javac $BEJVARGS ./njv/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ./njv/Base/target/jv
jar -cf ../../../BEL_${APPBLDNM}_jv.jar .
cd ../../../../

cd ../brace/system/jv
jar -cf ../../../${APPBLDNM}/njv/BEL_system_be_jv.jar .
cd ../../../${APPBLDNM}

#cp ../brace/lib/ex/jv/*.jar ./njv
#cp ../braceApp/lib/wa/jv/*.jar ./njv

#cp ../braceApp/extlibs/wa/jv/* ./njv
#cp extlibs/jv/* ./njv
rm -rf ./njv/Base
