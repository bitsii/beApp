mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IULink
rmdir /s /q ..\apprun\App\IULink
mkdir ..\apprun\App\IULink

set ADAPPDIR=..\iuad

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang jv --outputPlatform linux --emitFlag platDroid -mainClass=IULink:LinkStart source\IULink.be source\BrowserUI.be source\App.be source\BrowserJvAd.be source\Db.be

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang js --emitFlag platDroid --ownProcess false -mainClass=App:IULinkBr source\IULinkBr.be source\BrowserEUI.be

del /s /q %ADAPPDIR%\app\src\main\java\be
rmdir /s /q %ADAPPDIR%\app\src\main\java\be

xcopy /E ..\be\system\jv\*.java %ADAPPDIR%\app\src\main\java
xcopy /E ..\apprun\App\IULink\Base\target\jv\*.java %ADAPPDIR%\app\src\main\java

mkdir %ADAPPDIR%\app\src\main\assets\App\IULink
copy /y ..\apprun\App\IULink\Base\target\js\be\BEL_4_Base\BEL_4_Base.js %ADAPPDIR%\app\src\main\assets\App\IULink
copy /y source\IULink.html %ADAPPDIR%\app\src\main\assets\App\IULink
