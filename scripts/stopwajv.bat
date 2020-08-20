@echo off

pushd "%~dp0"

set i=0
:nextdir
set /a i+=1
for /f "tokens=%i% delims=\" %%a in ("%CD%") do if not "%%a" == "" set APPBLDNM=%%a& goto nextdir

cd ..\..

set MYPWD=%CD%

REM echo %APPBLDNM%
REM echo %MYPWD%
REM echo .

cscript App\%APPBLDNM%\stopwajv.vbs 
