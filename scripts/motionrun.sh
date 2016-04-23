#!/bin/bash

(motion -c $1 2>&1 | split -b 10485760 - /tmp/motion$$.dzlog) &
