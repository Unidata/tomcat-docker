#!/bin/bash

set -e
set -x

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

startup.sh

# never exit
while true; do sleep 10000; done

