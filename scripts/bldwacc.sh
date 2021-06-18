#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../braceApp/scripts/runwacc.sh ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../brace/target5/*;extlibs/jv/*;../braceApp/extlibs/jv/wa/*"
    ;;
  *)
    export CLASSPATH="../brace/target5/*:extlibs/jv/*:../braceApp/extlibs/jv/wa/*"
    ;;
esac

rm -rf ../apprun/App/$APPBLDNM/Base/target/cc ../apprun/App/$APPBLDNM/BEX_E_cl.exe

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cc --singleCC true --saveIds false --emitFlag ccSgc -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/WebServer.be ../braceApp/source/WebApp.be ../braceApp/source/Db.be ../braceApp/source/MFSKvDb.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../brace/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

time clang++ -DBEDCC_SGC=1 -pthread -o ../apprun/App/$APPBLDNM/BEX_E_cl.exe -ferror-limit=1 -std=c++14 ../apprun/App/$APPBLDNM/Base/target/cc/be/BEX_E.cpp -lsqlite3

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../brace/source/extended/Log.be ../braceApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../braceApp/extlibs/cc/wa/* ../apprun/App/$APPBLDNM
cp extlibs/cc/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
