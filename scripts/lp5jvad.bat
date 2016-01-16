mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\LocPing
rmdir /s /q ..\apprun\App\LocPing
mkdir ..\apprun\App\LocPing

set ADAPPDIR=..\andrapp2

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang jv --outputPlatform linux --emitFlag platDroid -mainClass=App:LocPing source\LocPing.be source\BrowserUI.be source\Db.be source\App.be source\BrowserJvAd.be

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang js --emitFlag platDroid --ownProcess false -mainClass=App:LocPing:LPBr source\LocPingBr.be source\BrowserEUI.be

del /s /q %ADAPPDIR%\app\src\main\java\be
rmdir /s /q %ADAPPDIR%\app\src\main\java\be

xcopy /E ..\be\system\jv\*.java %ADAPPDIR%\app\src\main\java
xcopy /E ..\apprun\App\LocPing\Base\target\jv\*.java %ADAPPDIR%\app\src\main\java

mkdir %ADAPPDIR%\app\src\main\assets\App\LocPing
copy /y ..\apprun\App\LocPing\Base\target\js\be\BEL_4_Base\BEL_4_Base.js %ADAPPDIR%\app\src\main\assets\App\LocPing
copy /y source\LocPing.html %ADAPPDIR%\app\src\main\assets\App\LocPing
