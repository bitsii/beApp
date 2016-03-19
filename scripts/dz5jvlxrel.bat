mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\Dz
rmdir /s /q ..\apprun\App\Dz
mkdir ..\apprun\App\Dz

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\Dz\d --buildPath ..\apprun\App\Dz --emitLang jv --outputPlatform linux -mainClass=Dz:Ui source\DzTest.be source\DzUi.be source\Db.be source\BrowserUI.be source\BrowserJvFx.be source\WebServer.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\jetty\*;extlibs\hsqldb\*;extlibs\bcastlejv\*;extlibs\javamail\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\Dz\Base\target\jv\be\BEL_4_Base\*.java

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\Dz\d --buildPath ..\apprun\App\Dz --emitLang js --outputPlatform linux --ownProcess false -mainClass=Dz:Eui source\DzEui.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\Dz\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\Dz\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\Dz\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\Dz\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\Dz\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\Dz
copy /y scripts\uppic.bat ..\apprun\App\Dz
copy /y scripts\uppic.sh ..\apprun\App\Dz
copy /y scripts\getcams.bat ..\apprun\App\Dz
copy /y scripts\getcams.sh ..\apprun\App\Dz
copy /y scripts\startdz.sh ..\apprun\App\Dz
copy /y scripts\dzrun.sh ..\apprun\App\Dz
copy /y scripts\dzcmdrs.sh ..\apprun\App\Dz
copy /y scripts\dzcmd.sh ..\apprun\App\Dz
copy /y source\Dz*.html ..\apprun\App\Dz
copy /y source\Version.txt ..\apprun\App\Dz
copy /y extlibs\jetty\* ..\apprun\App\Dz
copy /y extlibs\hsqldb\* ..\apprun\App\Dz
copy /y extlibs\bcastlejv\* ..\apprun\App\Dz
copy /y extlibs\javamail\* ..\apprun\App\Dz

del /s /q ..\apprun\App\Dz\Base
rmdir /s /q ..\apprun\App\Dz\Base
call scripts\relprep.bat

REM call scripts\dz5jvrun.bat %*
