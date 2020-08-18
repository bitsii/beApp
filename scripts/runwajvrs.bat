
pushd "%~dp0"

set i=0
:nextdir
set /a i+=1
for /f "tokens=%i% delims=\" %%a in ("%CD%") do if not "%%a" == "" set APPBLDNM=%%a& goto nextdir
REM echo Current location: %APPBLDNM%

cd ..\..

SET OPENSSL_CONF=..\Apache24\conf\openssl.cnf
REM SET MYPWD=\Edgii\SBridge\apprun
SET MYPWD=%cd%

SET MYHN=%ComputerName%

SET PATH=..\jv\bin;..\sc;..\up;..\Apache24\bin;..\gw\bin;%PATH%

REM if exist App\%APPBLDNM%\prers.bat call App\%APPBLDNM%\prers.bat

:loop

java.exe -classpath "App/%APPBLDNM%/*" be.BEX_E --myPwd %MYPWD% --runParams App/%APPBLDNM%/runParamsWa.txt %*
timeout /t 3

goto :loop

exit
