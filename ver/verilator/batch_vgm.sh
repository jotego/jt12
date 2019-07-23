#!/bin/bash

if [ ! -e "$1" ]; then
    echo "Cannot open folder $1"
    echo "Usage: batch_vgm.sh folder_to_scan seconds_to_simulate"
    echo "    batch_vgm.sh ../vgm 5   # will simulate 5s of all .vgz files in ../vgm"
    echo "Subfolders are scanned too"
    exit 1
fi

if [ "$2" = "" ];then
    SIMTIME=5000
else
    SIMTIME=$(($2 * 1000))
fi

GOPARAMS="-2610 -d NOSSG -nodecode -time $SIMTIME"
# Compiles the verilog to avoid the parallel command from issuing parallel compilations
go $GOPARAMS -f tests/adpcma.jtt -time 1

if [ -e nodes ]; then
    find $1 -name "*.vgz" | parallel --sshloginfile nodes 'cd github/jt12/ver/verilator; ./go $GOPARAMS -f {}'
else
    find $1 -name "*.vgz" | parallel go $GOPARAMS -f
fi
