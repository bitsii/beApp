#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../abeliiApp/scripts/runwacs.sh ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../abelii/target5/*;extlibs/jv/*;../abeliiApp/extlibs/jv/ba/*"
    ;;
  *)
    export CLASSPATH="../abelii/target5/*:extlibs/jv/*:../abeliiApp/extlibs/jv/ba/*"
    ;;
esac

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cs --emitFlag cswa --emitFlag relocMain -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abelii/source/extended/LogSink.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/Db.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mkdir -p cswa
rm cswa/BE*.cs
cp ../abelii/system/cs/be/*.cs cswa
cp ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs cswa

cd cswa
dotnet publish -o ../../apprun/App/$APPBLDNM
lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
cd ..

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
#cp ../abeliiApp/extlibs/jv/ba/* ../apprun/App/$APPBLDNM
#cp extlibs/jv/* ../apprun/App/$APPBLDNM

cd ../apprun/App/$APPBLDNM
