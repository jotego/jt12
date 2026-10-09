Writes the YM2203 timer registers through the jt03 bus. Checks that mode
`0x80` plus the Timer A load bit produces four channel-3 CSM keys without
enabling the timer IRQ. It then checks repeated overflow retriggers,
non-silent FM output, no timer status while its enable bit is clear, and
that mode `0xc0` does not enable CSM.
