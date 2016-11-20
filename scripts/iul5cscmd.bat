
mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\IULink
rmdir /s /q ..\apprun\App\IULink
mkdir ..\apprun\App\IULink

..\abe-pl\target5\BEL_4_Base_csc.exe ../abe-pl/source/base/Uses.be --buildFile build\shared.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang cs -mainClass=App:IULink --emitFlag foo source\IULink.be source\BrowserUI.be source\BrowserCsWf.be source\App.be source\Db.be 

if %errorlevel% neq 0 exit /b %errorlevel%

REM csc -debug /main:be.BeWebBrowser /warn:0 -out:..\apprun\App\IULink\BEL_4_Base_csc.exe /warn:0 ..\abe-pl\system\cs\be\*.cs ..\apprun\App\IULink\Base\target\cs\be\*.cs

if %errorlevel% neq 0 exit /b %errorlevel%

..\abe-pl\target5\BEL_4_Base_csc.exe ../abe-pl/source/base/Uses.be --buildFile build\base.txt --deployPath ..\apprun\App\IULink\d --buildPath ..\apprun\App\IULink --emitLang js --ownProcess false -mainClass=App:IULinkBr source\IULinkBr.be source\BrowserEUI.be

copy /y ..\apprun\App\IULink\Base\target\js\be\BEL_4_Base.js ..\apprun\App\IULink
copy /y source\IULink.html ..\apprun\App\IULink

if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

..\apprun\App\IULink\BEL_4_Base_csc.exe %*

REM if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\ioturl
