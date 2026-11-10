#!/bin/bash
# SPDX-FileCopyrightText: 2026 Andrea Bogazzi
# SPDX-License-Identifier: GPL-3.0-or-later
# Date: 04-11-2026
set -euo pipefail
suite_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$suite_dir/../../../.." && pwd)
reference_dir=${YMFM_SOURCE:-$HOME/develop/mame/3rdparty/ymfm/src}
image=${SIMULATOR_IMAGE:-jotego/simulator:arm64}
[[ -f "$reference_dir/ymfm_opn.cpp" ]] || { echo 'Set YMFM_SOURCE to the MAME ymfm/src folder' >&2; exit 1; }
docker image inspect "$image" >/dev/null
mkdir -p "$suite_dir/build" "$suite_dir/reports"
python3 - "${YM2608_ROM:-$HOME/.mame/roms-local/ym2608.zip}" "$suite_dir/build/rhythm.bin" <<'PYROM'
import pathlib,sys,zipfile
source=pathlib.Path(sys.argv[1])
if source.suffix.lower()==".zip":
    with zipfile.ZipFile(source) as archive:
        names=[x for x in archive.infolist() if x.file_size==8192]
        if len(names)!=1: raise SystemExit("Expected one8192-byte YM2608 rhythm ROM")
        data=archive.read(names[0])
else: data=source.read_bytes()
if len(data)!=8192: raise SystemExit("Expected an8192-byte YM2608 rhythm ROM")
pathlib.Path(sys.argv[2]).write_bytes(data)
PYROM
if [[ -n ${YM2608_SAMPLES:-} ]]; then cp "$YM2608_SAMPLES" "$suite_dir/build/external.bin"; fi
exec docker run --rm --pull=never --entrypoint /bin/bash \
    -v "$repo_dir:/jtcores" -v "$reference_dir:/ymfm:ro" \
    -w /jtcores/modules/jt12/ver/opna "$image" -euo pipefail -c '
        echo "{\"status\":\"building\"}" >reports/result.json
        sha256sum /ymfm/ymfm_opn.{cpp,h} /ymfm/ymfm_adpcm.{cpp,h} /ymfm/ymfm_ssg.{cpp,h} /ymfm/ymfm_fm.{h,ipp} /ymfm/ymfm.h >reports/reference.sha256
        find ../../hdl ../../jt49/hdl -maxdepth 1 -name "*.v" | sort >build/sources.f
        find ../../hdl/adpcm -maxdepth 1 -name "*.v" | sort >>build/sources.f
        verilator --cc --exe --build -j 4 --top-module jt08 \
            -Wno-fatal --Mdir build/obj -f build/sources.f \
            "$PWD/compare.cpp" /ymfm/ymfm_opn.cpp /ymfm/ymfm_adpcm.cpp /ymfm/ymfm_ssg.cpp \
            -CFLAGS "-std=c++17 -I/ymfm" >build/compile.log 2>&1
        exec build/obj/Vjt08 "$@"
    ' bash "$@"
