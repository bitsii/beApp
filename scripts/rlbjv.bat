mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\RLBeacon
rmdir /s /q ..\apprun\App\RLBeacon
mkdir ..\apprun\App\RLBeacon

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base ../be/source/base/Uses.be --buildFile build\shared.txt --deployPath ..\apprun\App\RLBeacon\d --buildPath ..\apprun\App\RLBeacon --emitLang jv -mainClass=RLBeacon:SiteStart source\RLBeacon.be ..\app\source\Db.be ..\app\source\BrowserUI.be ..\app\source\BrowserJvFx.be ..\app\source\WebServer.be ..\app\source\App.be ..\app\source\WebApp.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\RLBeacon\* ..\be\system\jv\be\*.java ..\apprun\App\RLBeacon\Base\target\jv\be\*.java

REM -Xlint:deprecation 

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base ../be/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\RLBeacon\d --buildPath ..\apprun\App\RLBeacon --emitLang js --ownProcess false -mainClass=RLBeacon:Eui source\RLBeaconBr.be ..\app\source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\RLBeacon\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\RLBeacon\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\RLBeacon\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\RLBeacon\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

REM hub
copy /y ..\apprun\App\RLBeacon\Base\target\js\be\BEL_4_Base.js ..\apprun\App\RLBeacon\RLBeacon_BEL_4_Base.js
REM copy /y scripts\upgrade.bat ..\apprun\App\RLBeacon
REM copy /y scripts\postupgrade.bat ..\apprun\App\RLBeacon
REM copy /y scripts\upgrade.sh ..\apprun\App\RLBeacon
REM copy /y scripts\upgrade2.sh ..\apprun\App\RLBeacon
REM copy /y scripts\postupgrade.sh ..\apprun\App\RLBeacon
copy /y scripts\startrls.sh ..\apprun\App\RLBeacon
copy /y scripts\rlsrun.sh ..\apprun\App\RLBeacon
copy /y scripts\rlscmdrs.sh ..\apprun\App\RLBeacon
copy /y scripts\rlscmd.sh ..\apprun\App\RLBeacon
copy /y source\RLBeacon*.html ..\apprun\App\RLBeacon
REM copy /y source\Version.txt ..\apprun\App\RLBeacon
copy /y extlibs\RLBeacon\* ..\apprun\App\RLBeacon

rem del /s /q ..\apprun\App\RLBeacon\Base
rem rmdir /s /q ..\apprun\App\RLBeacon\Base

call scripts\rlbcmd.bat %*

