mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IULink
rmdir /s /q ..\apprun\App\IULink
mkdir ..\apprun\App\IULink

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base ../be/source/base/Uses.be --buildFile build\shared.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang jv -mainClass=IULink:LinkStart --emitFlag foo source\IULink.be source\BrowserUI.be source\BrowserJvFx.be source\App.be source\Db.be source\WebServer.be

if %errorlevel% neq 0 exit /b %errorlevel%

javac -classpath extlibs\IULink\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\IULink\Base\target\jv\be\BEL_4_Base\*.java

if %errorlevel% neq 0 exit /b %errorlevel%

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base ../be/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang js --ownProcess false -mainClass=App:IULinkBr source\IULinkBr.be source\BrowserEUI.be

if %errorlevel% neq 0 exit /b %errorlevel%

del ..\apprun\App\IULink\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\IULink\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\IULink\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\IULink\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\IULink\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\IULink
copy /y source\IULink.html ..\apprun\App\IULink

copy /y extlibs\IULink\* ..\apprun\App\IULink

del /s /q ..\apprun\App\IULink\Base
rmdir /s /q ..\apprun\App\IULink\Base

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

java -classpath App\IULink\* be.BEL_4_Base.BEL_4_Base %*

cd ..\app

