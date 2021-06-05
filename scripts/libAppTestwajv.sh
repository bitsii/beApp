#!/bin/bash

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="$CLASSPATH;../abelii/lib/jv/*;lib/jv/*;extlibs/wa/jv/*;targetAppTestwa/AppTestwa/target/jv"
    ;;
  *)
    export CLASSPATH="$CLASSPATH:../abelii/lib/jv/*:lib/jv/*:extlibs/wa/jv/*:targetAppTestwa/AppTestwa/target/jv"
    ;;
esac

rm -rf targetAppTestwa

time mono --debug ../abelii/target5/BEX_E_mcs.exe ../abelii/source/base/Uses.be -deployPath=deployAppTestwa -buildPath=targetAppTestwa -libraryName=AppTestwa -mainClass=AppTest:Tests -loadSyns=lib/jv/BEL_Appwa.syn -loadIds=lib/jv/BEL_Appwa -initLib=Appwa --emitLang jv source/AppTest.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac targetAppTestwa/AppTestwa/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_AppTestwa $*

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
