/* This file is part of JT12.

 
    JT12 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT12 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT12.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 4-4-2019
*/

// VGM player for DE10-Nano board (MiSTer)
// This does not use the mister framework, only the board.

module vgm12(
);

wire signed [15:0] snd_right, snd_left;
wire [1:0]  fm_addr;
wire [7:0]  fm_din;

jt10 u_jt10(
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    .cen            ( fm_cen    ),        // optional clock enable, if not needed leave as 1'b1
    .din            ( fm_din    ),
    .addr           ( fm_addr   ),
    .cs_n           ( 1'b0      ),
    input           wr_n,
    
    output  [7:0]   dout,
    output          irq_n,
    // ADPCM pins
    output  [19:0]  adpcma_addr,  // real hardware has 10 pins multiplexed through RMPX pin
    output  [3:0]   adpcma_bank,
    output          adpcma_roe_n, // ADPCM-A ROM output enable
    input   [7:0]   adpcma_data,  // Data from RAM
    output  [23:0]  adpcmb_addr,  // real hardware has 12 pins multiplexed through PMPX pin
    output          adpcmb_roe_n, // ADPCM-B ROM output enable
    // Separated output: unused
    .psg_A          ( ),
    .psg_B          ( ),
    .psg_C          ( ),
    .fm_snd         ( ),
    // combined output
    .snd_right      ( snd_right ),
    .snd_left       ( snd_left  ),
    .snd_sample     ( )
);


endmodule