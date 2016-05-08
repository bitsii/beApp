#!/bin/bash

find Shared/WebCam -mtime +$1 -name "*.jpg" -exec rm {} \;
find Shared/WebCam -mtime +$1 -name "PICDIR_*" -exec rmdir {} \;
