mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\Bex
rmdir /s /q ..\apprun\App\Bex
mkdir ..\apprun\App\Bex

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\Bex\d --buildPath ..\apprun\App\Bex --emitLang jv -mainClass=App:Bex --emitFlag foo source\Bex.be source\BrowserUI.be source\BrowserJvFx.be source\App.be

javac ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\Bex\Base\target\jv\be\BEL_4_Base\*.java

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\Bex\d --buildPath ..\apprun\App\Bex --emitLang js --ownProcess false -mainClass=App:BexBr source\BexBr.be source\BrowserEUI.be

del ..\apprun\App\Bex\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\Bex\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\Bex\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\Bex\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\Bex\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\Bex
copy /y source\Bex.html ..\apprun\App\Bex

copy /y extlibs\hsqldb\* ..\apprun\App\Bex

del /s /q ..\apprun\App\Bex\Base
rmdir /s /q ..\apprun\App\Bex\Base

REM Run

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

java -classpath App\Bex\* be.BEL_4_Base.BEL_4_Base %*

cd ..\app
