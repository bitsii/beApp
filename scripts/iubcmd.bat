
@echo off

REM export MYPWD=`pwd`

REM export MYHN=`hostname`

mkdir Data\KBridge

jre\bin\java -classpath "App\KBridge\*" be.BEX_E --plugin App:PublicReadPlugin --plugin App:AuthPlugin --plugin App:FileManagerPlugin --plugin IUBridge:BridgePlugin --plugin App:ConfigPlugin --appPlugin KBridge %*

