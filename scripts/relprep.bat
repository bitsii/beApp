
call uglifyjs ..\apprun\App\IUHub\BEL_4_Base.js > ..\apprun\App\IUHub\BEL_4_Base.js.1

del /q ..\apprun\App\IUHub\BEL_4_Base.js

move ..\apprun\App\IUHub\BEL_4_Base.js.1 ..\apprun\App\IUHub\BEL_4_Base.js

cd ..\apprun\App\IUHub

del ..\..\..\IUHub.zip

zip ../IUHub.zip ./*

move ..\IUHub.zip ..\..\..

cd ..\..\..\app
