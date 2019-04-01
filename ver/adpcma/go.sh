#!/bin/bash

if which ncverilog; then
    ncverilog test.v adpcma_single.v ../../hdl/adpcm/jt10_{adpcm,adpcma_lut}.v +access+r
fi
