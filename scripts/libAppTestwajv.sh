#!/bin/bash

una=`uname -a`
case "$una" in
  *Msys*)
    export CLASSPATH="../brace/lib/ex/jv/*;lib/wa/jv/*;extlibs/wa/jv/*;targetAppTestwa/AppTest/target/jv"
    ;;
  *)
    export CLASSPATH="../brace/lib/ex/jv/*:lib/wa/jv/*:extlibs/wa/jv/*:targetAppTestwa/AppTest/target/jv"
    ;;
esac

rm -rf targetAppTestwa

time mono --debug ../brace/target5/BEX_E_mcs.exe ../brace/source/base/Uses.be -deployPath=deployAppTestwa -buildPath=targetAppTestwa -libraryName=AppTest -mainClass=AppTest:Tests -loadSyns=lib/wa/jv/BEL_App.syn -loadIds=lib/wa/jv/BEL_App -initLib=App --emitLang jv source/AppTest.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

javac targetAppTestwa/AppTest/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_AppTest $*

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
