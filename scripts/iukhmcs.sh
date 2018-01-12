#!/bin/bash

mono --debug ../abe-pl/target5/BEX_E_mcs.exe ../abe-pl/source/base/Uses.be --buildFile build/shared.txt --deployPath deployKh --buildPath targetKh --emitLang cs -mainClass=Konnectii:Host ../abe-pl/source/extended/Log.be source/IUKH.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mcs -debug:pdbonly -warn:0 -out:targetKh/BEX_E_mcs.exe ../abe-pl/system/cs/be/*.cs targetKh/Base/target/cs/be/*.cs

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#run
