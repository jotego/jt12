# JT12 FPGA Clone of Yamaha OPN hardware by Jose Tejada (@topapate)
===================================================================

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation


JT12 is an FM sound source written in Verilog, fully compatible with YM2612/YM3438 (Megadrive), YM2610 (NeoGeo) and YM2203 (PC88, arcades).

The implementation tries to be as close to original hardware as possible. Low usage of FPGA resources has also been a design goal. Except in the operator section (jt12_op) where an exact replica of the original circuit is done. This could be done in less space with a different style but because this piece of the circuit was reversed engineered by Sauraen, I decided to use that knowledge.

## Directories

* hdl -> all relevant RTL files, written in verilog
* ver -> test benches
* ver/verilator -> test bench that can play vgm files

## Usage

Chip    | Top Level     | QIP File
--------|---------------|---------
YM2610  |   jt10.v      | jt10.qip
YM2612  |   jt12.v      | jt12.qip
YM2203  |   jt03.v      | jt03.qip

## Simulation

There are several simulation test benches in the **ver** folder. The most important one is in the **ver/verilator** folder. The simulation script is called with the shell script **go** in the same folder. The script will compile the file **test.cpp** together with other files and the design and will simulate the tune specificied with the -f command. It can read **vgm** tunes and generate .wav output of them.

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)