#!/bin/bash

FILES="test.v ../../hdl/adpcm/jt10_adpcm_div.v"

if which ncverilog; then
    ncverilog $FILES +access+r +define+NCVERILOG
else
    if ! which iverilog; then
        echo "ERROR: Cannot find any valid verilog simualtor."
        exit 1
    fi
    iverilog $FILES -o sim && sim -fst
fi
