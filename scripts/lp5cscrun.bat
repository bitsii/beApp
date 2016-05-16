
cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

..\apprun\App\LocPing\BEL_4_Base_csc.exe %*

REM if %errorlevel% neq 0 exit /b %errorlevel%

cd ..\app
