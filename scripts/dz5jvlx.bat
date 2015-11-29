mkdir ..\apprun
mkdir ..\apprun\dzdata

del /s /q ..\apprun\dz

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\dzd --buildPath ..\apprun\dz --emitLang jv --outputPlatform linux -mainClass=Dz:Lui source\Dz.be source\DzTest.be source\DzUi.be source\Db.be source\BrowserUI.be

javac -source 1.7 -target 1.7 -classpath extlibs\jetty\*;extlibs\sqlite\*;extlibs\derby\*;extlibs\bcastlejv\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\dz\Base\target\jv\be\BEL_4_Base\*.java

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\dzd --buildPath ..\apprun\dz --emitLang js --outputPlatform linux --ownProcess false -mainClass=Dz:Eui source\DzEui.be

del ..\apprun\dz\BEL_4_Base_lui_jv.jar
cd ..\apprun\dz\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\app

del ..\apprun\dz\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\dz\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y ..\apprun\dz\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\dz
copy /y scripts\uppic.bat ..\apprun\dz
copy /y source\Dz*.html ..\apprun\dz
copy /y source\Dz*.js ..\apprun\dz
copy /y extlibs\jetty\* ..\apprun\dz
copy /y extlibs\sqlite\* ..\apprun\dz
copy /y extlibs\derby\* ..\apprun\dz
copy /y extlibs\bcastlejv\* ..\apprun\dz

call scripts\dz5jvrun.bat %*
