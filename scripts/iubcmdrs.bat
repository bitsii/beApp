
@echo off

REM export MYPWD=`pwd`

REM export MYHN=`hostname`

mkdir Data\KBridge

FOR /L %%A IN (0,0,1) DO (
  jre\bin\java -classpath "App\KBridge\*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin App:ConfigPlugin --appPlugin KBridge --appType server %*
  timeout 1
)


