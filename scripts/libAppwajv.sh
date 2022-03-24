#!/bin/bash

una=`uname -a`

rm -rf lib/wa/jv/BEL_App_*

export CLASSPATH=../brace/target5/*
time java -XX:-UsePerfData -XX:TieredStopAtLevel=1 -XX:+UseSerialGC be.BEL_Base --buildFile build/libAppwa.txt --emitLang jv --doMain false -loadSyns=../brace/lib/ex/jv/BEL_Base.syn -loadIds=../brace/lib/ex/jv/BEL_Base -initLib=Base

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

case "$una" in
  *Msys*)
    export CLASSPATH="../brace/lib/ex/jv/*;extlibs/wa/jv/*"
    ;;
  *)
    export CLASSPATH="../brace/lib/ex/jv/*:extlibs/wa/jv/*"
    ;;
esac

javac lib/wa/App/target/jv/be/*.java

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf lib/wa/jv
mkdir lib/wa/jv
mv lib/wa/App/target/jv/be/*.ids lib/wa/jv
mv lib/wa/App/target/jv/be/*.syn lib/wa/jv
rm -f lib/wa/App/target/jv/be/*.java

rm -f lib/wa/jv/BEL_App.jar
cd lib/wa/App/target/jv
jar -cf ../../../jv/BEL_App.jar .
cd ../../../../..
rm -rf lib/wa/App
