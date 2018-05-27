#!/bin/bash

echo $0 $1 >> /tmp/picUpload.log

./App/KBridge/iuhcmd.sh --appType cmd --bridgeCmd sftpFile --sourceFile $1
