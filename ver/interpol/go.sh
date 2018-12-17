#!/bin/bash

EXTRA=

while [ $# -gt 0 ]; do
    if [ "$1" = "-nofm" ]; then
        EXTRA="$EXTRA -DNOFM"
        shift
        continue
    fi
    if [ "$1" = "-w" ]; then
        EXTRA="$EXTRA -DDUMP_ALL"
        shift
        continue
    fi
    if [ "$1" = "-time" ]; then
        shift
        EXTRA="$EXTRA -DFINISH_AT=$1"
        shift
        continue
    fi
    echo Unknown argument: $1
    exit 1
done

# echo $EXTRA
if ! verilator --lint-only jt12_genmix.v -I../../hdl; then
    exit $?
fi
iverilog test.v ../../hdl/jt12_{genmix,interpol,decim,comb}.v $EXTRA -o sim && sim -lxt