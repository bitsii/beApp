#!/bin/bash

export RELMKS="yes"

../beApp/scripts/bldwajv.sh $*
../beApp/scripts/relwajv.sh $*
../beApp/scripts/mkswajv.sh $*

