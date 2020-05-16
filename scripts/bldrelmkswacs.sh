#!/bin/bash

export RELMKS="yes"

../abeliiApp/scripts/bldwacs.sh $*
../abeliiApp/scripts/relwacs.sh $*
../abeliiApp/scripts/mkswacs.sh $*

