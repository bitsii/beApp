#!/bin/bash

una=`uname -a`

rm -rf targetAppTestwa

export CLASSPATH=../beBase/target5/*
time java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base ../beBase/source/base/Uses.be -deployPath=deployAppTestwa -buildPath=targetAppTestwa -libraryName=AppTest -mainClass=AppTest:Tests -loadSyns=lib/wa/jv/BEL_App.syn -loadIds=lib/wa/jv/BEL_App -initLib=App --emitLang jv source/AppTest.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../beBase/lib/ex/jv/*;lib/wa/jv/*;extlibs/wa/jv/*;targetAppTestwa/AppTest/target/jv"
    ;;
  *)
    export CLASSPATH="../beBase/lib/ex/jv/*:lib/wa/jv/*:extlibs/wa/jv/*:targetAppTestwa/AppTest/target/jv"
    ;;
esac

javac targetAppTestwa/AppTest/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

java be.BEL_AppTest $*

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi
