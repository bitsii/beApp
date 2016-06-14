
mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IotUrl
rmdir /s /q ..\apprun\App\IotUrl
mkdir ..\apprun\App\IotUrl

..\be\target5\BEL_4_Base_csc.exe --buildFile build\shared.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang cs -mainClass=App:IotUrl --emitFlag foo source\IotUrl.be source\BrowserUI.be source\BrowserCsWf.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

csc -debug /main:be.BEL_4_Base.BeWebBrowser /warn:0 -out:..\apprun\App\IotUrl\BEL_4_Base_csc.exe /warn:0 ..\be\system\cs\be\BELS_Base\*.cs ..\apprun\App\IotUrl\Base\target\cs\be\BEL_4_Base\*.cs

if %errorlevel% neq 0 exit /b %errorlevel%

..\be\target5\BEL_4_Base_csc.exe --buildFile build\base.txt --deployPath ..\apprun\App\IotUrl\d --buildPath ..\apprun\App\IotUrl --emitLang js --ownProcess false -mainClass=App:IotUrlBr source\IotUrlBr.be source\BrowserEUI.be

copy /y ..\apprun\App\IotUrl\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\IotUrl
copy /y source\IotUrl.html ..\apprun\App\IotUrl

if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

..\apprun\App\IotUrl\BEL_4_Base_csc.exe %*

REM if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\app
