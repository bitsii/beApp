#!/bin/bash

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="$CLASSPATH;../abelii/lib/jv/*;extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="$CLASSPATH:../abelii/lib/jv/*:extlibs/wa/jv/*"
    ;;
esac

rm -rf lib/jv/BEL_Base_*

time mono --debug ../abelii/target5/BEX_E_mcs.exe --buildFile build/libAppwa.txt --emitLang jv --doMain false -loadSyns=../abelii/lib/jv/BEL_Base.syn -loadIds=../abelii/lib/jv/BEL_Base -initLib=Base

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac lib/Appwa/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf lib/jv
mkdir lib/jv
mv lib/Appwa/target/jv/be/*.ids lib/jv
mv lib/Appwa/target/jv/be/*.syn lib/jv
rm -f lib/Appwa/target/jv/be/*.java

rm -f lib/jv/BEL_Appwa.jar
cd lib/Appwa/target/jv
jar -cf ../../../jv/BEL_Appwa.jar .
cd ../../../..
rm -rf lib/Appwa
