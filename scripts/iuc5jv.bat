mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IUCam
rmdir /s /q ..\apprun\App\IUCam
mkdir ..\apprun\App\IUCam

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\IUCam\d --buildPath ..\apprun\App\IUCam --emitLang jv -mainClass=IUCam:Ui source\IUCam.be source\Db.be source\BrowserUI.be source\BrowserJvFx.be source\WebServer.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\IUCam\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\IUCam\Base\target\jv\be\BEL_4_Base\*.java

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\IUCam\d --buildPath ..\apprun\App\IUCam --emitLang js --ownProcess false -mainClass=IUCam:Eui source\IUCamBr.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\IUCam\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\IUCam\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\IUCam\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\IUCam\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\IUCam\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\IUCam
copy /y scripts\uppic.bat ..\apprun\App\IUCam
copy /y scripts\uppic.sh ..\apprun\App\IUCam
copy /y scripts\getcams.bat ..\apprun\App\IUCam
copy /y scripts\getcams.sh ..\apprun\App\IUCam
REM copy /y scripts\startiuc.sh ..\apprun\App\IUCam
REM copy /y scripts\iucrun.sh ..\apprun\App\IUCam
REM copy /y scripts\iuccmdrs.sh ..\apprun\App\IUCam
REM copy /y scripts\iuccmd.sh ..\apprun\App\IUCam
copy /y scripts\motionrun.sh ..\apprun\App\IUCam
copy /y scripts\camclean.sh ..\apprun\App\IUCam
copy /y source\IUCam*.html ..\apprun\App\IUCam
copy /y source\Version.txt ..\apprun\App\IUCam
copy /y source\MOCAM.conf ..\apprun\App\IUCam
copy /y extlibs\IUCam\* ..\apprun\App\IUCam

rem del /s /q ..\apprun\App\IUCam\Base
rem rmdir /s /q ..\apprun\App\IUCam\Base

call scripts\iuc5jvrun.bat %*
