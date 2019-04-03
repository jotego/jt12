#!/bin/bash

if which ncverilog; then
    ncverilog test.v adpcma_single.v ../../hdl/adpcm/jt10_{adpcm,adpcma_lut}.v \
        +access+r +define+NCVERILOG
else
    if ! which iverilog; then
        echo "ERROR: Cannot find any valid verilog simualtor."
        exit 1
    fi
    iverilog test.v adpcma_single.v ../../hdl/adpcm/jt10_{adpcm,adpcma_lut}.v -o sim && sim -fst
fi

# generate wave files
if [ ! -e ../../cc/dec2wav ]; then
    x=$(pwd)
    cd ../../cc
    make dec2wav
    cd $x
fi

for i in *.val; do
    ../../cc/dec2wav $i 18500
done
