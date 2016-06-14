
mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\Bex
rmdir /s /q ..\apprun\App\Bex
mkdir ..\apprun\App\Bex

..\be\target5\BEL_4_Base_csc.exe --buildFile build\shared.txt --deployPath ..\apprun\App\Bex\d --buildPath ..\apprun\App\Bex --emitLang cs -mainClass=App:BrowserExample --emitFlag foo source\Bex.be source\BrowserUI.be source\BrowserCsWf.be source\App.be

if %errorlevel% neq 0 exit /b %errorlevel%

csc -debug /main:be.BEL_4_Base.BeWebBrowser /warn:0 -out:..\apprun\App\Bex\BEL_4_Base_csc.exe /warn:0 ..\be\system\cs\be\BELS_Base\*.cs ..\apprun\App\Bex\Base\target\cs\be\BEL_4_Base\*.cs

if %errorlevel% neq 0 exit /b %errorlevel%

..\be\target5\BEL_4_Base_csc.exe --buildFile build\base.txt --deployPath ..\apprun\App\Bex\d --buildPath ..\apprun\App\Bex --emitLang js --ownProcess false -mainClass=App:BexBr source\BexBr.be source\BrowserEUI.be

copy /y ..\apprun\App\Bex\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\App\Bex
copy /y source\Bex.html ..\apprun\App\Bex

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

..\apprun\App\Bex\BEL_4_Base_csc.exe %*

REM if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\app

if %errorlevel% neq 0 exit /b %errorlevel%
