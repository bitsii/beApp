
cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

java -classpath App\LocPing\* be.BEL_4_Base.BEL_4_Base %*

cd ..\app
