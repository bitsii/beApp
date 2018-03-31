#!/bin/bash

until /home/pi/openhab/start.sh $*; do
    echo "Exited code $?.  Will restart.." >&2
    sleep 1
done

