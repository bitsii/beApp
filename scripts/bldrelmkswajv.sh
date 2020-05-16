#!/bin/bash

export RELMKS="yes"

../abeliiApp/scripts/bldwajv.sh $*
../abeliiApp/scripts/relwajv.sh $*
../abeliiApp/scripts/mkswajv.sh $*

