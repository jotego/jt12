#!/bin/bash

if [ ! -e "$1" ]; then
    echo "Cannot open folder $1"
    exit 1
fi

find $1 -name "*.vgz" | parallel go -2610 -time 8000 -nodecode -f