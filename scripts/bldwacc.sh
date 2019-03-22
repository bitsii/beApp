#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../abeliiApp/scripts/runwacc.sh ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/jv/*;../abeliiApp/extlibs/jv/wa/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/jv/*:../abeliiApp/extlibs/jv/wa/*"
    ;;
esac

rm -rf ../apprun/App/$APPBLDNM/Base/target/cc ../apprun/App/$APPBLDNM/BEX_E_cl.exe

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cc --singleCC true --saveIds false --emitFlag ccSgc -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/WebServer.be ../abeliiApp/source/WebApp.be ../abeliiApp/source/Db.be ../abeliiApp/source/SlDbJv.be   

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../abelii/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

time clang++ -DBEDCC_SGC=1 -pthread -o ../apprun/App/$APPBLDNM/BEX_E_cl.exe -ferror-limit=1 -std=c++14 ../apprun/App/$APPBLDNM/Base/target/cc/be/BEX_E.cpp -lsqlite3

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../abeliiApp/extlibs/cc/wa/* ../apprun/App/$APPBLDNM
cp extlibs/cc/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
