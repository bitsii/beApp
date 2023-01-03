#!/bin/bash

mono --debug ../beBase/target5/BEX_E_mcs.exe ../beBase/source/base/Uses.be --buildFile build/shared.txt --deployPath deployKh --buildPath targetKh --emitLang cs -mainClass=Konnectii:Host ../beBase/source/extended/Log.be source/IUKH.be

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

mcs -debug:pdbonly -warn:0 -out:targetKh/BEX_E_mcs.exe ../beBase/system/cs/be/*.cs targetKh/Base/target/cs/be/*.cs

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

#run
#--wpaSup test/wpa_supplicant.conf --ssid yo --psk there
mono --debug targetKh/BEX_E_mcs.exe $*

