mkdir ..\apprun

SET TEST_APPDATA=..\apprun\jotad

del /s /q ..\apprun\jo\Base\target\jv

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\jod --buildPath ..\apprun\jo --emitLang jv -mainClass=Ve:Lui source\Jot.be source\BrowserUI.be

javac -classpath extlibs\jetty\*;extlibs\sqlite\*;extlibs\bcastlejv\* ..\be\system\jv\be\BELS_Base\*.java ..\apprun\jo\Base\target\jv\be\BEL_4_Base\*.java

del ..\apprun\jo\BEL_4_Base_lui_jv.jar
cd ..\apprun\jo\Base\target\jv
jar -cf ..\..\..\BEL_4_Base_lui_jv.jar .
cd ..\..\..\..\..\app

del ..\apprun\jo\BEL_4_Base_lib_jv.jar
cd ..\be\system\jv
jar -cf ..\..\..\apprun\jo\BEL_4_Base_lib_jv.jar .
cd ..\..\..\app

cd ..\be\system
del /s *.class
cd ..\..\app

copy /y source\JotUi.html ..\apprun\jo

java -classpath ..\apprun\jo\*;extlibs\jetty\*;extlibs\sqlite\*;extlibs\bcastlejv\* be.BEL_4_Base.BEL_4_Base %*
