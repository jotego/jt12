#!/bin/bash

find ../vgm/ym2610 -name "*.vgz" | parallel go -2610 -d NOMIX -nodecode -f