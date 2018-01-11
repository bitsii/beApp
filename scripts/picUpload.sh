#!/bin/bash

echo $0 $1 >> /tmp/picUpload.log

./App/IUHub/iuhcmd.sh --appType cmd --bridgeCmd sftpFile --sourceFile $1
