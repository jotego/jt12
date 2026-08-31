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
*/

// YM2610B wrapper
// Clock enabled at 7.5 - 8.5MHz

module jt10b(
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [7:0]   din,
    input   [1:0]   addr,
    input           cs_n,
    input           wr_n,

    output  [7:0]   dout,
    output          irq_n,
    // ADPCM pins
    output  [19:0]  adpcma_addr,  // real hardware has 10 pins multiplexed through RMPX pin
    output  [4:0]   adpcma_bank,
    output          adpcma_roe_n, // ADPCM-A ROM output enable
    input   [7:0]   adpcma_data,  // Data from RAM
    output  [23:0]  adpcmb_addr,  // real hardware has 12 pins multiplexed through PMPX pin
    output          adpcmb_roe_n, // ADPCM-B ROM output enable
    input   [7:0]   adpcmb_data,
    // Separated output
    output          [ 7:0] psg_A,
    output          [ 7:0] psg_B,
    output          [ 7:0] psg_C,
    output      signed [15:0] fm_left, fm_right,
    // combined output
    output          [ 9:0] psg_snd,
    output      signed [15:0] snd_right, snd_left,
    output          snd_sample,
    input           [ 5:0] ch_enable // ADPCM-A channels
);

wire signed [15:0] fm_only_l, fm_only_r;
wire signed [15:0] adpcma_l, adpcma_r, adpcmb_l, adpcmb_r;

jt10b_mixer u_left(
    .clk       ( clk          ),
    .cen       ( cen          ),
    .fm_in     ( fm_only_l    ),
    .adpcma_in ( adpcma_l     ),
    .adpcmb_in ( adpcmb_l     ),
    .psg_in    ( psg_snd      ),
    .fm_out    ( fm_left      ),
    .snd_out   ( snd_left     )
);

jt10b_mixer u_right(
    .clk       ( clk          ),
    .cen       ( cen          ),
    .fm_in     ( fm_only_r    ),
    .adpcma_in ( adpcma_r     ),
    .adpcmb_in ( adpcmb_r     ),
    .psg_in    ( psg_snd      ),
    .fm_out    ( fm_right     ),
    .snd_out   ( snd_right    )
);

jt12_top #(
    .use_lfo(1), .use_ssg(1), .num_ch(6), .use_pcm(0), .use_adpcm(1),
    .FULLFM(1), .JT49_DIV(3)
) u_jt12(
    .rst            ( rst          ),
    .clk            ( clk          ),
    .cen            ( cen          ),
    .din            ( din          ),
    .addr           ( addr         ),
    .cs_n           ( cs_n         ),
    .wr_n           ( wr_n         ),

    .dout           ( dout         ),
    .irq_n          ( irq_n        ),
    // ADPCM pins
    .adpcma_addr    ( adpcma_addr  ),
    .adpcma_bank    ( adpcma_bank  ),
    .adpcma_roe_n   ( adpcma_roe_n ),
    .adpcma_data    ( adpcma_data  ),
    .adpcmb_addr    ( adpcmb_addr  ),
    .adpcmb_roe_n   ( adpcmb_roe_n ),
    .adpcmb_data    ( adpcmb_data  ),
    // Separated output
    .psg_A          ( psg_A        ),
    .psg_B          ( psg_B        ),
    .psg_C          ( psg_C        ),
    .psg_snd        ( psg_snd      ),
    .fm_snd_left    ( fm_only_l    ),
    .fm_snd_right   ( fm_only_r    ),
    .adpcmA_l       ( adpcma_l     ),
    .adpcmA_r       ( adpcma_r     ),
    .adpcmB_l       ( adpcmb_l     ),
    .adpcmB_r       ( adpcmb_r     ),
    // Unused YM2203
    .IOA_in         ( 8'b0         ),
    .IOB_in         ( 8'b0         ),
    .IOA_out        (              ),
    .IOB_out        (              ),
    .IOA_oe         (              ),
    .IOB_oe         (              ),
    .debug_bus      ( 8'd0         ),
    // Sound output
    .snd_right      (              ),
    .snd_left       (              ),
    .snd_sample     ( snd_sample   ),
    .ch_enable      ( ch_enable    ),
    // unused pins
    .en_hifi_pcm    ( 1'b0         ),
    .debug_view     (              )
);

endmodule
