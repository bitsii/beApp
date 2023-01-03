#!/bin/bash

export RELMKS="yes"

../beApp/scripts/bldwacs.sh $*
../beApp/scripts/relwacs.sh $*
../beApp/scripts/mkswacs.sh $*

