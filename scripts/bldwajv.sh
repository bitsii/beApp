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

cp ../braceApp/scripts/runwajv.sh ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/runwajvrs.sh ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/stopwajvrs.sh ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/runwajv.bat ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/runwajvex.bat ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/runwajvrs.bat ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/runwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/stopwajvrs.bat ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/stopwajvrs.vbs ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/stopwajv.bat ../apprun/App/$APPBLDNM
cp ../braceApp/scripts/stopwajv.vbs ../apprun/App/$APPBLDNM

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="$CLASSPATH;../braceApp/lib/wa/jv/*;../brace/lib/ex/jv/*;extlibs/jv/*;../braceApp/extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="$CLASSPATH:../braceApp/lib/wa/jv/*:../brace/lib/ex/jv/*:extlibs/jv/*:../braceApp/extlibs/wa/jv/*"
    ;;
esac

if [ ! -z "$BEPREBUILD" -a "$BEPREBUILD" != " " ]; then
  eval "$BEPREBUILD"
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --buildFile ../braceApp/build/shared.txt --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM --emitLang jv -mainClass=App:AppStart --buildFile build/build.txt $BEBLDARGS 

time mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -libraryName=$APPBLDNM -mainClass=App:AppStart -loadSyns=../braceApp/lib/wa/jv/BEL_App.syn -loadIds=../braceApp/lib/wa/jv/BEL_App -initLib=App --emitLang jv --buildFile build/build.txt $BEBLDARGS

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#javac $BEJVARGS ../brace/system/jv/be/*.java ../apprun/App/$APPBLDNM/Base/target/jv/be/*.java

javac $BEJVARGS ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

if [ -e build/buildbr.txt ]; then
  time mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be $BRBLDARGS --deployPath ../apprun/App/$APPBLDNM/d --buildPath ../apprun/App/$APPBLDNM -libraryName=$APPBLDNM -loadSyns=../braceApp/lib/wabr/js/BEL_App.syn -initLib=App -jsInclude=../braceApp/lib/wabr/js/BEL_App.js --emitLang js --ownProcess false --buildFile build/buildbr.txt
fi

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

cd ../apprun/App/$APPBLDNM/$APPBLDNM/target/jv
jar -cf ../../../BEL_${APPBLDNM}_jv.jar .
cd ../../../../../../$APPBLDNM

cp ../brace/lib/ex/jv/*.jar ../apprun/App/$APPBLDNM
cp ../braceApp/lib/wa/jv/*.jar ../apprun/App/$APPBLDNM

if [ -e build/buildbr.txt ]; then
  cp ../apprun/App/$APPBLDNM/$APPBLDNM/target/js/be/BEL_${APPBLDNM}.js ../apprun/App/$APPBLDNM/BEX_E.js
fi
cp -R resources/* ../apprun/App/$APPBLDNM
cp ../braceApp/extlibs/wa/jv/* ../apprun/App/$APPBLDNM
cp extlibs/jv/* ../apprun/App/$APPBLDNM
rm -rf ../apprun/App/$APPBLDNM/$APPBLDNM/target

#cd ../apprun/App/$APPBLDNM
