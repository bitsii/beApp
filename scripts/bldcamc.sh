#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../braceApp/scripts/runcamc.sh ../apprun/App/$APPBLDNM

if [ ! -z "$BEPREBUILD" -a "$BEPREBUILD" != " " ]; then
  eval "$BEPREBUILD"
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cs -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../brace/source/extended/Log.be ../brace/source/extended/LogSink.be ../braceApp/source/App.be ../braceApp/source/BrowserUI.be ../braceApp/source/Db.be   

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mcs -debug:pdbonly -warn:0 -out:../apprun/App/$APPBLDNM/BEX_E_mcs.exe ../brace/system/cs/be/*.cs ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp -R resources/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
