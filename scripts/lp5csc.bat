
mkdir ..\apprun
mkdir ..\apprun\App
mkdir ..\apprun\Data

del /s /q ..\apprun\App\LocPing
rmdir /s /q ..\apprun\App\LocPing
mkdir ..\apprun\App\LocPing

..\be\target5\BEL_4_Base_csc.exe --buildFile build\shared.txt --deployPath ..\apprun\App\LocPing\d --buildPath ..\apprun\App\LocPing --emitLang cs -mainClass=App:LocPing --emitFlag foo source\LocPing.be source\BrowserUI.be source\BrowserUI.be source\App.be

csc -debug /warn:0 -out:..\apprun\App\LocPing\BEL_4_Base_csc.exe /warn:0 ..\be\system\cs\be\BELS_Base\*.cs ..\apprun\App\LocPing\Base\target\cs\be\BEL_4_Base\*.cs











rmdir targetEc\Base\target\cs /s /q
del targetEc\BEL_4_Base_csc.exe
target5\BEL_4_Base_csc.exe --buildFile build\extendedEc.txt --emitLang cs

if %errorlevel% neq 0 exit /b %errorlevel%

csc -debug /warn:0 -out:targetEc\BEL_4_Base_csc.exe /warn:0 system\cs\be\BELS_Base\*.cs targetEc\Base\target\cs\be\BEL_4_Base\*.cs
targetEc\BEL_4_Base_csc.exe %*

if %errorlevel% neq 0 exit /b %errorlevel%
