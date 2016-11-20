mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IUHub
rmdir /s /q ..\apprun\App\IUHub
mkdir ..\apprun\App\IUHub

java -classpath ..\abe-pl\target5\BEL_system_be_jv.jar;..\abe-pl\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build\shared.txt --deployPath ..\apprun\App\IUHub\d --buildPath ..\apprun\App\IUHub --emitLang jv -mainClass=IUHub:HubStart source\IUHubTest.be source\IUHub.be source\Db.be source\BrowserUI.be source\BrowserJvFx.be source\WebServer.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\IUHub\* ..\abe-pl\system\jv\be\BELS_Base\*.java ..\apprun\App\IUHub\Base\target\jv\be\BEL_4_Base\*.java

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\abe-pl\target5\BEL_system_be_jv.jar;..\abe-pl\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base ../abe-pl/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\IUHub\d --buildPath ..\apprun\App\IUHub --emitLang js --ownProcess false -mainClass=IUHub:Eui source\IUHubBr.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\IUHub\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\IUHub\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\ioturl

del ..\apprun\App\IUHub\BEL_4_Base_lib_jv.jar
cd ..\abe-pl\system\jv
jar -cf ..\..\..\apprun\App\IUHub\BEL_4_Base_lib_jv.jar .
cd ..\..\..\ioturl

cd ..\abe-pl\system
del /s *.class
cd ..\..\ioturl

copy /y ..\apprun\App\IUHub\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\IUHub\IUHub_BEL_4_Base.js
copy /y scripts\upgrade.bat ..\apprun\App\IUHub
copy /y scripts\postupgrade.bat ..\apprun\App\IUHub
copy /y scripts\upgrade.sh ..\apprun\App\IUHub
copy /y scripts\upgrade2.sh ..\apprun\App\IUHub
copy /y scripts\postupgrade.sh ..\apprun\App\IUHub
copy /y scripts\startiuh.sh ..\apprun\App\IUHub
copy /y scripts\iuhrun.sh ..\apprun\App\IUHub
copy /y scripts\iuhcmdrs.sh ..\apprun\App\IUHub
copy /y scripts\iuhcmd.sh ..\apprun\App\IUHub
copy /y source\IUHub*.html ..\apprun\App\IUHub
copy /y source\Version.txt ..\apprun\App\IUHub
copy /y extlibs\IUHub\* ..\apprun\App\IUHub

rem del /s /q ..\apprun\App\IUHub\Base
rem rmdir /s /q ..\apprun\App\IUHub\Base

call scripts\iuh5jvrun.bat %*
