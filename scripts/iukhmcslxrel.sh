#!/bin/bash

mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile build/shared.txt --deployPath deployKh --buildPath targetKh --emitLang cs --outputPlatform linux -mainClass=Konnectii:Host ../abelii/source/extended/Log.be source/IUKH.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mcs -debug:pdbonly -warn:0 -out:targetKh/BEX_E_mcs.exe ../abelii/system/cs/be/*.cs targetKh/Base/target/cs/be/*.cs

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#run
#mono --debug targetKh/BEX_E_mcs.exe $*

mkdir -p ../apprun/App/IUKH

cp targetKh/BEX_E_mcs.exe ../apprun/App/IUKH
cp scripts/startiuk.sh ../apprun/App/IUKH
cp scripts/iukrun.sh ../apprun/App/IUKH
cp scripts/iukcmd.sh ../apprun/App/IUKH
cp scripts/setupIukh.sh ../apprun/App/IUKH
cp scripts/iukhost.conf ../apprun/App/IUKH
cp scripts/dlbinstall.sh ../apprun/App/IUKH
cp LICENSE.txt ../apprun/App/IUKH
cp LICENSE-MPL.txt ../apprun/App/IUKH

cd ../apprun/App

rm -f IUKH.zip
zip -r IUKH.zip IUKH

cp IUKH.zip ../..

cd ../../edgii
