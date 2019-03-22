#!/bin/bash

python gen_sine.py > sine.hex

if which ncverilog &> /dev/null; then
    ncverilog +access+r +nc64bit +define+NCVERILOG \
        test.v ../../hdl/adpcm/jt10_adpcm_acc.v
else
    echo "To do: add iverilog simulation statement"
fi
