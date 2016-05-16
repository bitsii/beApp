
mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\LocPing
rmdir /s /q ..\apprun\App\LocPing
mkdir ..\apprun\App\LocPing

..\be\target5\BEL_4_Base_csc.exe --buildFile build\shared.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang cs -mainClass=App:LocPing --emitFlag foo source\LocPing.be source\BrowserUI.be source\BrowserCsWf.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

csc -debug /main:be.BEL_4_Base.BeWebBrowser /warn:0 -out:..\apprun\App\LocPing\BEL_4_Base_csc.exe /warn:0 ..\be\system\cs\be\BELS_Base\*.cs ..\apprun\App\LocPing\Base\target\cs\be\BEL_4_Base\*.cs

if %errorlevel% neq 0 exit /b %errorlevel%

..\be\target5\BEL_4_Base_csc.exe --buildFile build\base.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang js --ownProcess false -mainClass=App:LocPing:LPBr source\LocPingBr.be source\BrowserEUI.be

copy /y ..\apprun\App\LocPing\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\LocPing
copy /y source\LocPing.html ..\apprun\App\LocPing

call scripts\lp5cscrun.bat %*

if %errorlevel% neq 0 exit /b %errorlevel%
