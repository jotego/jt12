# JT12 FPGA Clone of Yamaha OPN hardware by Jose Tejada (@topapate)
===================================================================

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation


JT12 is an FM sound source written in Verilog, fully compatible with YM2612 and YM2203.

The implementation tries to be as close to original hardware as possible. Low usage of FPGA resources has also been a design goal. Except in the operator section (jt12_op) where an exact replica of the original circuit is done. This could be done in less space with a different style but because this piece of the circuit was reversed engineered by Sauraen, I decided to use that knowledge.

Directories:

hdl -> all relevant RTL files, written in verilog
ver -> test benches
ver/verilator -> test bench that can play vgm files

Usage:

YM2612: top level file "jt12.v". Use jt12.qip to automatically get all relevant files in Quartus.
    YM2612 should have parameters set like:
        use_lfo = 1
        use_psg = 0

YM2203: top level file "jt12.v". Use jt03.qip to automatically get all relevant files in Quartus.
    YM2203 should have parameters set like:
        use_lfo = 0
        use_psg = 1

