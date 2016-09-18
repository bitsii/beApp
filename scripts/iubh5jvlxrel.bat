mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IUHub
rmdir /s /q ..\apprun\App\IUHub
mkdir ..\apprun\App\IUHub

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base ../be/source/base/Uses.be --buildFile build\shared.txt --deployPath ..\apprun\App\IUHub\d --buildPath ..\apprun\App\IUHub --emitLang jv --outputPlatform linux -mainClass=IUHub:BigHubStart source\IUHubTest.be source\IUHub.be source\IUCam.be source\IUBigHub.be source\Db.be source\BrowserUI.be source\BrowserJvFx.be source\WebServer.be source\App.be source\WebApp.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\IUHub\* ..\be\system\jv\be\*.java ..\apprun\App\IUHub\Base\target\jv\be\*.java

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base ../be/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\IUHub\d --buildPath ..\apprun\App\IUHub --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUHub:Eui source\IUHubBr.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base ../be/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\IUCam\d --buildPath ..\apprun\App\IUCam --emitLang js --outputPlatform linux --ownProcess false -mainClass=IUCam:Eui source\IUCamBr.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\IUHub\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\IUHub\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\IUHub\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\IUHub\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

REM hub
copy /y ..\apprun\App\IUHub\Base\target\js\be\BEL_4_Base.js ..\apprun\App\IUHub\IUHub_BEL_4_Base.js
copy /y scripts\upgrade.bat ..\apprun\App\IUHub
copy /y scripts\postupgrade.bat ..\apprun\App\IUHub
copy /y scripts\upgrade.sh ..\apprun\App\IUHub
copy /y scripts\upgrade2.sh ..\apprun\App\IUHub
copy /y scripts\postupgrade.sh ..\apprun\App\IUHub
copy /y scripts\startiuh.sh ..\apprun\App\IUHub
copy /y scripts\createAdminAccount.sh ..\apprun\App\IUHub
copy /y scripts\iuhrun.sh ..\apprun\App\IUHub
copy /y scripts\iuhcmdrs.sh ..\apprun\App\IUHub
copy /y scripts\iuhcmd.sh ..\apprun\App\IUHub
copy /y source\IUHub*.html ..\apprun\App\IUHub
copy /y source\Version.txt ..\apprun\App\IUHub
REM copy /y extlibs\IUHub\* ..\apprun\App\IUHub

REM cam
copy /y ..\apprun\App\IUCam\Base\target\js\be\BEL_4_Base.js ..\apprun\App\IUHub\IUCam_BEL_4_Base.js
copy /y scripts\uppic.bat ..\apprun\App\IUHub
copy /y scripts\uppic.sh ..\apprun\App\IUHub
copy /y scripts\getcams.bat ..\apprun\App\IUHub
copy /y scripts\getcams.sh ..\apprun\App\IUHub
REM copy /y scripts\startiuc.sh ..\apprun\App\IUHub
REM copy /y scripts\iucrun.sh ..\apprun\App\IUHub
REM copy /y scripts\iuccmdrs.sh ..\apprun\App\IUHub
REM copy /y scripts\iuccmd.sh ..\apprun\App\IUHub
copy /y scripts\motionrun.sh ..\apprun\App\IUHub
copy /y scripts\camclean.sh ..\apprun\App\IUHub
copy /y source\IUCam*.html ..\apprun\App\IUHub
copy /y source\Version.txt ..\apprun\App\IUHub
copy /y source\MOCAM.conf ..\apprun\App\IUHub
REM copy /y extlibs\IUCam\* ..\apprun\App\IUHub

del /s /q ..\apprun\App\IUHub\Base
rmdir /s /q ..\apprun\App\IUHub\Base

call uglifyjs ..\apprun\App\IUHub\IUHub_BEL_4_Base.js > ..\apprun\App\IUHub\IUHub_BEL_4_Base.js.1
del /q ..\apprun\App\IUHub\IUHub_BEL_4_Base.js
move ..\apprun\App\IUHub\IUHub_BEL_4_Base.js.1 ..\apprun\App\IUHub\IUHub_BEL_4_Base.js

call uglifyjs ..\apprun\App\IUHub\IUCam_BEL_4_Base.js > ..\apprun\App\IUHub\IUCam_BEL_4_Base.js.1
del /q ..\apprun\App\IUHub\IUCam_BEL_4_Base.js
move ..\apprun\App\IUHub\IUCam_BEL_4_Base.js.1 ..\apprun\App\IUHub\IUCam_BEL_4_Base.js

cd ..\apprun\App\IUHub

del ..\..\..\IUBHub.zip

zip ../IUBHub.zip ./*

move ..\IUBHub.zip ..\..\..

cd ..\..\..\app

