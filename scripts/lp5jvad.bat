mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\LocPing
rmdir /s /q ..\apprun\App\LocPing
mkdir ..\apprun\App\LocPing

set ADAPPDIR=..\andrapp2

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang jv --outputPlatform linux --emitFlag platAndroid -mainClass=App:LocPing source\LocPing.be source\BrowserUI.be source\BrowserJvAd.be

del /s /q %ADAPPDIR%\app\src\main\java\be
rmdir /s /q %ADAPPDIR%\app\src\main\java\be

xcopy /E ..\be\system\jv\*.java %ADAPPDIR%\app\src\main\java
xcopy /E ..\apprun\App\LocPing\Base\target\jv\*.java %ADAPPDIR%\app\src\main\java

