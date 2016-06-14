mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IotUrl
rmdir /s /q ..\apprun\App\IotUrl
mkdir ..\apprun\App\IotUrl

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang jv -mainClass=App:IotUrl --emitFlag foo source\IotUrl.be source\BrowserUI.be source\BrowserJvFx.be source\App.be

javac ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\IotUrl\Base\target\jv\be\BEL_4_Base\*.java

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang js --ownProcess false -mainClass=App:IotUrlBr source\IotUrlBr.be source\BrowserEUI.be

del ..\apprun\App\IotUrl\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\IotUrl\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\IotUrl\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\IotUrl\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\IotUrl\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\IotUrl
copy /y source\IotUrl.html ..\apprun\App\IotUrl

copy /y extlibs\hsqldb\* ..\apprun\App\IotUrl

del /s /q ..\apprun\App\IotUrl\Base
rmdir /s /q ..\apprun\App\IotUrl\Base

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

java -classpath App\IotUrl\* be.BEL_4_Base.BEL_4_Base %*

cd ..\app

