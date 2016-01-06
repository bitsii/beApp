mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\Dz
rmdir /s /q ..\apprun\App\Dz
mkdir ..\apprun\App\Dz

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\Dz\d --buildPath ..\apprun\App\Dz --emitLang jv --outputPlatform linux -mainClass=Dz:Ui source\Dz.be source\DzTest.be source\DzUi.be source\Db.be source\BrowserUI.be source\BrowserJvFx.be source\WebServer.be

javac -classpath extlibs\jetty\*;extlibs\sqlite\*;extlibs\derby\*;extlibs\bcastlejv\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\Dz\Base\target\jv\be\BEL_4_Base\*.java

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\Dz\d --buildPath ..\apprun\App\Dz --emitLang js --outputPlatform linux --ownProcess false -mainClass=Dz:Eui source\DzEui.be source\BrowserEUI.be

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
copy /y source\Dz*.html ..\apprun\App\Dz
copy /y source\Dz*.js ..\apprun\App\Dz
copy /y extlibs\jetty\* ..\apprun\App\Dz
copy /y extlibs\derby\* ..\apprun\App\Dz
copy /y extlibs\bcastlejv\* ..\apprun\App\Dz

del /s /q ..\apprun\App\Dz\Base
rmdir /s /q ..\apprun\App\Dz\Base

REM call scripts\dz5jvrun.bat %*
