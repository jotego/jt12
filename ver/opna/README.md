---
title: YM2608 comparison
author: Andrea Bogazzi
---

# YM2608 comparison

Run `modules/jt12/ver/opna/run.sh` from the JTCORES checkout. The runner uses
an installed `jotego/simulator:arm64` image and compiles the RTL with MAME's
YMFM reference in one Verilator executable. `SIMULATOR_IMAGE` selects another
installed image; `YMFM_SOURCE` selects the directory containing `ymfm_opn.cpp`.
No reference source is copied into this repository. `YM2608_ROM` selects the
8 KiB rhythm ROM, either raw or zipped; its default is
`~/.mame/roms-local/ym2608.zip`. ROM bytes are never tracked.

`jt08` combines JT12 FM, JT49 SSG, the JT10 rhythm and Delta-T decoders, new
OPNA register/memory controllers and a wide stereo mixer. The digital output
includes FM, rhythm and Delta-T. SSG outputs remain separate for board mixing.
Existing chip variants default to `OPNA=0`.

The comparison covers bank selection, identification, defined SSG register bits,
GPIO, SSG oscillation, three/six FM channels, stereo panning, prescalers,
timers, IRQ masks, all six rhythm instruments, Delta-T rates, saturation,
stop/repeat/limit addressing, EOS/BRDY, CPU streaming and CPU RAM reads/writes.
The external byte interface holds address, direction, data and chip select
until `adpcm_ok`; the bench checks both short and delayed responses. Rhythm ROM
reads must settle before the next enabled chip clock.

Waveform CSVs preserve raw RTL/reference samples. Isolated FM tone vectors use
algorithm 7 with one keyed operator; they do not establish equivalence of all
algorithms, envelopes, LFO or CSM. PCM assertions compare FM after a bounded
-4..0 sample alignment, rhythm after -2..0 and Delta-T after -4..4 samples,
excluding startup.
This establishes sample arithmetic for those vectors, not identical bus-to-audio
latency. SSG frequency tests do not establish analog amplitude equivalence.
`bus.csv` retains the readback mask: YMFM preserves reserved SSG register bits
which JT49 masks. GPIO output tests write while configured as outputs.

To replay captured chip writes, set `YM2608_SAMPLES` to the game's external
sample ROM and pass `--trace /jtcores/path/to/trace.csv`. Each row contains
`chip_clock,port,data`, using monotonically increasing master-clock counts and
ports 0..3. An optional final `fm`, `rhythm` or `delta` argument isolates that
component while retaining transaction times. The default replays everything.
The runner adds a quarter-second tail and writes `game-audio.csv`,
`game-rtl.wav`, `game-mame.wav` and correlation/gain measurements in `result.json`.
WAV files contain the digital stereo output at 8 MHz / 144; SSG is separate in
the CSV. Game comparisons report measured agreement rather than asserting a
bit-exact match. Reference sample phase is initialized once after chip reset.

Build products and reports are ignored. `reference.sha256` identifies the YMFM
sources used for each run. Tail to Nose's board entrypoint is
`cores/ttnose/ver/game/sound.sh`; `--compare-only` reuses its existing trace.

ADPCM timing currently targets the default /6 prescaler used by Tail to Nose;
FM/SSG prescaler changes are covered separately. Analog recording/ADC encoding,
ZERO detection and direct DAC modes remain unimplemented.
YMFM also lacks the analog recording path. These tests use software reference
outputs; no original-chip hardware measurements are available.
