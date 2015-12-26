
del /s /q ..\apprun\dz\Base
rmdir /s /q ..\apprun\dz\Base

del /s /q ..\apprun\dz\Home
rmdir /s /q ..\apprun\dz\Home

del /s /q ..\apprun\dz\cert
del /s/q ..\apprun\dz\derby.log

call uglifyjs ..\apprun\dz\BEL_4_Base.js > ..\apprun\dz\BEL_4_Base.js.1

del /q ..\apprun\dz\BEL_4_Base.js

move ..\apprun\dz\BEL_4_Base.js.1 ..\apprun\dz\BEL_4_Base.js
