mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IotUrl
rmdir /s /q ..\apprun\App\IotUrl
mkdir ..\apprun\App\IotUrl

set ADAPPDIR=..\iuad

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\shared.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang jv --outputPlatform linux --emitFlag platDroid -mainClass=App:IotUrl source\IotUrl.be source\BrowserUI.be source\App.be source\BrowserJvAd.be source\Db.be

java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang js --emitFlag platDroid --ownProcess false -mainClass=App:IotUrlBr source\IotUrlBr.be source\BrowserEUI.be

del /s /q %ADAPPDIR%\app\src\main\java\be
rmdir /s /q %ADAPPDIR%\app\src\main\java\be

xcopy /E ..\be\system\jv\*.java %ADAPPDIR%\app\src\main\java
xcopy /E ..\apprun\App\IotUrl\Base\target\jv\*.java %ADAPPDIR%\app\src\main\java

mkdir %ADAPPDIR%\app\src\main\assets\App\IotUrl
copy /y ..\apprun\App\IotUrl\Base\target\js\be\BEL_4_Base\BEL_4_Base.js %ADAPPDIR%\app\src\main\assets\App\IotUrl
copy /y source\IotUrl.html %ADAPPDIR%\app\src\main\assets\App\IotUrl
