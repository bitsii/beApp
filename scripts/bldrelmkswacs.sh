#!/bin/bash

export RELMKS="yes"

../braceApp/scripts/bldwacs.sh $*
../braceApp/scripts/relwacs.sh $*
../braceApp/scripts/mkswacs.sh $*

