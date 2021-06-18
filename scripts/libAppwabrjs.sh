#!/bin/bash

rm -rf lib/wabr/js/BEL_Base_*

time mono --debug ../brace/target5/BEX_E_mcs.exe --buildFile build/libAppwabr.txt --emitLang js --ownProcess false -loadSyns=../brace/lib/br/js/BEL_Base.syn --initLib Base

lae=$?;if [[ $lae -ne 0 ]]; then exit $lae; fi

rm -rf lib/wabr/js
mkdir lib/wabr/js
mv lib/wabr/App/target/js/be/*.syn lib/wabr/js
mv lib/wabr/App/target/js/be/*.js lib/wabr/js
rm -rf lib/wabr/App