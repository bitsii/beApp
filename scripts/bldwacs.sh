#!/bin/bash

export APPBLDNM=${PWD##*/}

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../abeliiApp/scripts/runwacs.sh ../apprun/App/$APPBLDNM
#cp ../abeliiApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM

una=`uname -a`

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang cs -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS ../abelii/source/extended/Log.be ../abeliiApp/source/App.be ../abeliiApp/source/BrowserUI.be ../abeliiApp/source/WebServer.be ../abeliiApp/source/WebApp.be ../abeliiApp/source/Db.be ../abeliiApp/source/SlDbCs.be 

rm csaweb/csaweb/BE*.cs
cp ../abelii/system/cs/be/*.cs csaweb/csaweb
cp ../abeliiApp/system/cs/*.cs csaweb/csaweb
cp ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs csaweb/csaweb

rm -rf csaweb/csaweb/App/$APPBLDNM


lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

msbuild /t:Clean,Build csaweb/csaweb.sln

#cp csaweb/csaweb/bin/* ../apprun/App/$APPBLDNM
#cp csaweb/csaweb/Global.asax ../apprun/App/$APPBLDNM

#javac $BEJVARGS ../abelii/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

#msbuild/sbuild
#mcs $BECSARGS -debug:pdbonly -warn:0 -out:../apprun/App/$APPBLDNM/BEX_E_app_cs.exe ../abelii/system/cs/be/*.cs ../abelii/system/cs/be/*.cs ../apprun/App/$APPBLDNM/Base/target/cs/be/*.cs

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#cd ../apprun/App/$APPBLDNM/Base/target/jv
#jar -cf ../../../BEX_E_app_jv.jar .
#cd ../../../../../../$APPBLDNM

#cd ../abelii/system/jv
#jar -cf ../../../apprun/App/$APPBLDNM/BEX_E_lib_jv.jar .
#cd ../../../$APPBLDNM

#find ../abelii/system -name "*.class" -exec rm {} \;

cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEX_E.js ../apprun/App/$APPBLDNM/BEX_E.js
cp -R resources/* ../apprun/App/$APPBLDNM
#cp ../abeliiApp/extlibs/cs/wa/* ../apprun/App/$APPBLDNM
#cp extlibs/cs/* ../apprun/App/$APPBLDNM

mkdir -p csaweb/csaweb/App
cp -R ../apprun/App/$APPBLDNM csaweb/csaweb/App

cd ../apprun/App/$APPBLDNM
