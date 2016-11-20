
cd ..\apprun

set "MYPWD=%cd%"

for /f "delims=" %%a in ('hostname') do @set MYHN=%%a

java -classpath App\RLBeacon\* be.BEL_4_Base %*

cd ..\ioturl
