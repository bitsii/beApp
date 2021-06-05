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

if [ "$BERCDONE" != "true" ]; then
  if [ -e "./build/build${BLDPLAT}rcjv.sh" ]; then
    . "./build/build${BLDPLAT}rcjv.sh"
  fi
fi

mkdir -p ../apprun
mkdir -p ../apprun/App
mkdir -p ../apprun/Data
mkdir -p ../apprun/Data/$APPBLDNM

rm -rf ../apprun/App/$APPBLDNM
mkdir -p ../apprun/App/$APPBLDNM

cp ../abeliiApp/scripts/runwajv.sh ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/stopwajvrs.sh ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/runwajv.bat ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/runwajvex.bat ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/runwajvrs.bat ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/runwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/stopwajvrs.bat ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/stopwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/stopwajv.bat ../apprun/App/$APPBLDNM
cp ../abeliiApp/scripts/stopwajv.vbs ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="$CLASSPATH;../abeliiApp/lib/jv/*;../abelii/lib/jv/*;extlibs/jv/*;../abeliiApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="$CLASSPATH:../abeliiApp/lib/jv/*:../abelii/lib/jv/*:extlibs/jv/*:../abeliiApp/extlibs/wa/jv/*"
    ;;
esac

if [ ! -z "$BEPREBUILD" -a "$BEPREBUILD" != " " ]; then
  eval "$BEPREBUILD"
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS 

time mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -libraryName=$APPBLDNM -mainClass=App:AppStart -loadSyns=../abeliiApp/lib/jv/BEL_Appwa.syn -loadIds=../abeliiApp/lib/jv/BEL_Appwa -initLib=Appwa --emitLang jv --buildFile build/build.txt $BEBLDARGS

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../abelii/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

javac $BEJVARGS ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

if [ -e build/buildbr.txt ]; then
  mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be --buildFile ../abeliiApp/build/base.txt $BRBLDARGS --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang js --ownProcess false --buildFile build/buildbr.txt ../abelii/source/extended/Log.be ../abeliiApp/source/BrowserEUI.be
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv
jar -cf ../../../BEL_${APPBLDNM}_jv.jar .
cd ../../../../../../$APPBLDNM

cp ../abelii/lib/jv/*.jar ../apprun/App/$APPBLDNM
cp ../abeliiApp/lib/jv/*.jar ../apprun/App/$APPBLDNM

if [ -e build/buildbr.txt ]; then
  cp ../apprun/App/$APPBLDNM/Base/target/js/be/BEL_Base.js ../apprun/App/$APPBLDNM/BEX_E.js
fi
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../abeliiApp/extlibs/wa/jv/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM

#cd ../apprun/App/$APPBLDNM
