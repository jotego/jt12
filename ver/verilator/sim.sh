#!/bin/bash

TOP=top
DUMPSIGNALS=
EXTRA=
GYM_FILE=
GYM_ARG=
FAST=-DFASTDIV
VERI_EXTRA="-DSIMULATION"
WAV_FILE=
CHIPTYPE="-DYM2612 -DMEGADRIVE_PSG"
SKIPMAKE=FALSE

function set_slow {
    FAST=
    EXTRA="$EXTRA -slow"
}

function show_help {
    cat <<EOF
go: verilator simulation of .vgm, .gym and .jtt files
    Usage:
    -f          input file
    -t | -time  maximum simulation time in ms
    -o          output wav file name
    -2203       forces YM2203 mode
    -2610       forces YM2610 mode
    -d macro    defines an additional verilog macro
    -w          enable signal dump
    -w1         signal dump of only top level
    -w0 time    signal dump enabled at specified time
    -slow       clock dividers enabled (slows down simulation)
    -hex        hexadecimal dump enabled
    -nomix      does not mix the different sound sources
    -noam       disables AM feature
    -noks       disables KS feature
    -nomul      disables MUL feature
    -mute
    -nodecode
    -runonly    skips verilator compilation and tries to run the already existing binary
    -help       shows this help
EOF
}

#function eval_args {
    while [ $# -gt 0 ]; do
        case "$1" in
        "-w")
            echo "Signal dump enabled"
            DUMPSIGNALS="-trace";;
        "-w0")
            shift
            echo "Signal dump enabled from time $1"
            DUMPSIGNALS="-trace"
            EXTRA="$EXTRA -trace_start $1";;
        "-slow")
            echo "Clock divider enabled"
            set_slow;;
        "-hex")
            echo "Hexadecimal dump enabled"
            FAST=
            EXTRA="$EXTRA -hex";;
        "-w1")
            echo "Signal dump enabled (only top level)"
            DUMPSIGNALS="-trace"
            VERI_EXTRA="$VERI_EXTRA --trace-depth 1";;
        "-f")
            shift
            if [ ! -e "$1" ]; then
                echo "Cannot open file " $1 " for GYM parsing"
                exit 1
            fi
            GYM_ARG="-gym"
            GYM_FILE="$1"
            if [[ "$WAV_FILE" == "" ]]; then
                WAV_FILE=$(basename "$GYM_FILE" .vgm).wav
            fi;;
        "-time" | "-t")
            shift
            EXTRA="$EXTRA -time $1";;
        "-o")
            shift
            WAV_FILE="$1";;
        "-2203")
            echo "YM2203 mode (you should also use -slow too if the audio output is important)"
            CHIPTYPE="-DYM2203 -DMEGADRIVE_PSG";;
        "-2610")
            echo "YM2610 mode. The simulation will use real clock dividers for ADCPM accuracy."
            CHIPTYPE="-DYM2610"
            set_slow;;
        "-noam" | "-noks" | "-nomul" | "-mute" | "-nodecode")
            EXTRA="$EXTRA $1"
            if [[ "$1" = -mute ]]; then
                shift
                EXTRA="$EXTRA $1"
            fi;;
        "-d")
            shift
            VERI_EXTRA="-D$1 $VERI_EXTRA";;
        "-nomix")
            VERI_EXTRA="-DNOMIX $VERI_EXTRA"
            EXTRA="$EXTRA $1";;
        "-runonly")
            echo Skipping Verilator and make steps
            SKIPMAKE=TRUE;;
        -h|--help|-help)
            show_help
            exit 0;;
        *)
            echo go: unrecognized option $1
            exit 1
        esac
        shift
    done
#}

#eval_args $JT12_VERILATOR $*

if [[ "$GYM_FILE" = "" ]]; then
    echo "Specify the VGM/GYM/JTT file to parse using the argument -f file_name"
    exit 1
fi

echo EXTRA="$EXTRA"

if [[ $(expr match "$GYM_FILE" ".*\.vgz") != 0 ]]; then
    echo Uncompressing vgz file...
    UNZIP_GYM=$(basename "$GYM_FILE" .vgz).vgm
    if [ -e /tmp ]; then
        UNZIP_GYM="/tmp/$UNZIP_GYM"
    fi
    WAV_FILE=$(basename "$UNZIP_GYM" .vgm).wav
    gunzip -S vgz "$GYM_FILE" --to-stdout > "$UNZIP_GYM"
else
    UNZIP_GYM=$GYM_FILE
fi

date

# Link files located in ../../cc
# Maybe I could just reference to files there, but it is not
# so obvious how to do it with Verilator Makefile so I just
# add them here
if [ ! -e WaveWritter.cpp ]; then
    ln -s ../../cc/WaveWritter.cpp
fi

if [ ! -e WaveWritter.hpp ]; then
    ln -s ../../cc/WaveWritter.hpp
fi

if [ $SKIPMAKE = FALSE ]; then
    echo "verilator --cc -f gather.f test.v $CHIPTYPE --top-module $TOP \
        -I../../hdl -I../../jt89/hdl --trace -DTEST_SUPPORT \
        $VERI_EXTRA $FAST --exe test.cpp VGMParser.cpp WaveWritter.cpp"

    if ! verilator --timescale 1ns/1ps --cc -f gather.f test.v $CHIPTYPE --top-module $TOP \
        -I../../hdl -I../../jt89/hdl --trace -DTEST_SUPPORT \
        $VERI_EXTRA $FAST --exe test.cpp VGMParser.cpp WaveWritter.cpp; then
        exit $?
    fi

    if ! make -j -C obj_dir -f V${TOP}.mk V${TOP}; then
        exit $?
    fi
    echo Simulation start...
    echo obj_dir/V${TOP} $DUMPSIGNALS $EXTRA  $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE"
fi

if [[ $DUMPSIGNALS == "-trace" ]]; then
    if which vcd2fst; then
        # Verilator VCD output goes through standard output
        echo VCD to FST conversion running in parallel
        # filter out lines starting with INFO: because these come from $display commands in verilog and are
        # routed to standard output but are not part of the VCD file
        obj_dir/V${TOP} $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" |  grep -v "^INFO: " | vcd2fst -v - -f test.fst
    else
        if which simvisdbutil; then
            obj_dir/V${TOP} $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" | grep -v "^INFO: " > test.vcd
            echo VCD to SST2 conversion
            simvisdbutil test.vcd -output test -overwrite -shm && rm test.vcd
        else
            obj_dir/V${TOP} $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE" > test.vcd
        fi
    fi
else
    obj_dir/V${TOP} $DUMPSIGNALS $EXTRA $GYM_ARG "$UNZIP_GYM" -o "$WAV_FILE"
fi