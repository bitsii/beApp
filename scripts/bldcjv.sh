#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../braceApp/scripts/runcjv.sh ../apprun/App/$APPBLDNM
#cp ../braceApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../brace/target5/*;extlibs/jv/*;../braceApp/extlibs/jv/ca/*"
    ;;
  *)
    export CLASSPATH="../brace/target5/*:extlibs/jv/*:../braceApp/extlibs/jv/ca/*"
    ;;
esac

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be  

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac $BEJVARGS ../brace/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/Base/target/jv
jar -cf ../../../BEX_E_app_jv.jar .
cd ../../../../../../$APPBLDNM

cd ../brace/system/jv
jar -cf ../../../apprun/App/$APPBLDNM/BEX_E_lib_jv.jar .
cd ../../../$APPBLDNM

find ../brace/system -name "*.class" -exec rm {} \;

cp -R resources/* ../apprun/App/$APPBLDNM
cp ../braceApp/extlibs/jv/ca/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
