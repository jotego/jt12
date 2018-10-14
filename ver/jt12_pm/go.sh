#!/bin/bash

iverilog jt12_pm_tb.v ../../hdl/jt12_pm.v -o sim && sim -lxt