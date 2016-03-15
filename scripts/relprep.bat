
call uglifyjs ..\apprun\App\Dz\BEL_4_Base.js > ..\apprun\App\Dz\BEL_4_Base.js.1

del /q ..\apprun\App\Dz\BEL_4_Base.js

move ..\apprun\App\Dz\BEL_4_Base.js.1 ..\apprun\App\Dz\BEL_4_Base.js

cd ..\apprun\App\Dz

del ..\..\..\Dz.zip

zip ..\..\..\Dz.zip *

cd ..\..\..\app
