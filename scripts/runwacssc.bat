
pushd "%~dp0"

set i=0
:nextdir
set /a i+=1
for /f "tokens=%i% delims=\" %%a in ("%CD%") do if not "%%a" == "" set APPBLDNM=%%a& goto nextdir

cd ..\..

SET MYHN=%ComputerName%

start /min .\App\%APPBLDNM%\cswa.exe --runParams App/%APPBLDNM%/runParamsWa.txt %*

exit
