#!/bin/bash

export RELMKS="yes"

../braceApp/scripts/bldwajv.sh $*
../braceApp/scripts/relwajv.sh $*
../braceApp/scripts/mkswajv.sh $*

