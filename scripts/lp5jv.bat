mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\LocPing
rmdir /s /q ..\apprun\App\LocPing
mkdir ..\apprun\App\LocPing

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang jv -mainClass=App:LocPing source\LocPing.be source\BrowserUI.be

javac ..\be\system\jv\be\BELS_Base\*.java ..\apprun\App\LocPing\Base\target\jv\be\BEL_4_Base\*.java

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang js --ownProcess false -mainClass=App:LocPing:LPBr source\LocPingBr.be source\BrowserEUI.be

del ..\apprun\App\LocPing\BEL_4_Base_lui_jv.jar
cd ..\apprun\App\LocPing\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\..\app

del ..\apprun\App\LocPing\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\App\LocPing\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\App\LocPing\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\LocPing
copy /y source\LocPing.html ..\apprun\App\LocPing

del /s /q ..\apprun\App\LocPing\Base
rmdir /s /q ..\apprun\App\LocPing\Base

call scripts\lp5jvrun.bat %*
