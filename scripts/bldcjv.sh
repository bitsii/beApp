#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../abeliiApp/scripts/runcjv.sh ../apprun/App/$APPBLDNM
#cp ../abeliiApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/jv/*;../abeliiApp/extlibs/jv/ca/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/jv/*:../abeliiApp/extlibs/jv/ca/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be  

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac $BEJVARGS ../abelii/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/Base/target/jv
jar -cf ../../../BEX_E_app_jv.jar .
cd ../../../../../../$APPBLDNM

cd ../abelii/system/jv
jar -cf ../../../apprun/App/$APPBLDNM/BEX_E_lib_jv.jar .
cd ../../../$APPBLDNM

find ../abelii/system -name "*.class" -exec rm {} \;

cp -R resources/* ../apprun/App/$APPBLDNM
cp ../abeliiApp/extlibs/jv/ca/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
