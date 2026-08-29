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
    Date: 21-03-2019
*/

// YM2610 wrapper
// Clock enabled at 7.5 - 8.5MHz

module jt10(
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
    // Sound output
    output          [ 9:0] psg_snd,
    output  signed  [15:0] fm_left,
    output  signed  [15:0] fm_right,
    output  signed  [15:0] pcm_left,
    output  signed  [15:0] pcm_right,
    output  signed  [15:0] dig_left,
    output  signed  [15:0] dig_right,
    output          snd_sample,
    input           [ 5:0] ch_enable // ADPCM-A channels
);

wire signed [15:0] adpcma_l, adpcma_r, adpcmb_l, adpcmb_r;

function signed [15:0] limsum2;
    input signed [15:0] a, b;
    reg   signed [16:0] full;
begin
    full    = {a[15],a} + {b[15],b};
    limsum2 = full[16] == full[15] ? full[15:0] :
              full[16] ? 16'h8000 : 16'h7fff;
end
endfunction

function signed [15:0] limsum3;
    input signed [15:0] a, b, c;
    reg   signed [17:0] full;
begin
    full    = {{2{a[15]}},a} + {{2{b[15]}},b} + {{2{c[15]}},c};
    limsum3 = (&full[17:15] || ~|full[17:15]) ? full[15:0] :
              full[17] ? 16'h8000 : 16'h7fff;
end
endfunction

assign pcm_left  = limsum2(adpcma_l,adpcmb_l);
assign pcm_right = limsum2(adpcma_r,adpcmb_r);
assign dig_left  = limsum3(fm_left,adpcma_l,adpcmb_l);
assign dig_right = limsum3(fm_right,adpcma_r,adpcmb_r);

// Uses 6 FM channels but only 4 are outputted
jt12_top #(
    .use_lfo(1),.use_ssg(1), .num_ch(6), .use_pcm(0), .use_adpcm(1),
    .mix_adpcm(1'b0), .JT49_DIV(3) )
u_jt12(
    .rst            ( rst          ),        // rst should be at least 6 clk&cen cycles long
    .clk            ( clk          ),        // CPU clock
    .cen            ( cen          ),        // optional clock enable, it not needed leave as 1'b1
    .din            ( din          ),
    .addr           ( addr         ),
    .cs_n           ( cs_n         ),
    .wr_n           ( wr_n         ),

    .dout           ( dout         ),
    .irq_n          ( irq_n        ),
    // ADPCM pins
    .adpcma_addr    ( adpcma_addr  ), // real hardware has 10 pins multiplexed through RMPX pin
    .adpcma_bank    ( adpcma_bank  ),
    .adpcma_roe_n   ( adpcma_roe_n ), // ADPCM-A ROM output enable
    .adpcma_data    ( adpcma_data  ), // Data from RAM
    .adpcmb_addr    ( adpcmb_addr  ), // real hardware has 12 pins multiplexed through PMPX pin
    .adpcmb_roe_n   ( adpcmb_roe_n ), // ADPCM-B ROM output enable
    .adpcmb_data    ( adpcmb_data  ), // Data from RAM
    // Separated output
    .psg_A          (              ),
    .psg_B          (              ),
    .psg_C          (              ),
    .psg_snd        ( psg_snd      ),
    .fm_snd_left    ( fm_left      ),
    .fm_snd_right   ( fm_right     ),
    .adpcmA_l       ( adpcma_l     ),
    .adpcmA_r       ( adpcma_r     ),
    .adpcmB_l       ( adpcmb_l     ),
    .adpcmB_r       ( adpcmb_r     ),
    // Unused YM2203
    // unused
    .IOA_in         ( 8'b0          ),
    .IOB_in         ( 8'b0          ),
    .IOA_out        (               ),
    .IOB_out        (               ),
    .IOA_oe         (               ),
    .IOB_oe         (               ),
    .debug_bus      ( 8'd0          ),
    // Sound output
    .snd_right      (              ),
    .snd_left       (              ),
    .snd_sample     ( snd_sample   ),
    .ch_enable      ( ch_enable    ),
    // unused pins
    .en_hifi_pcm    ( 1'b0         ), // used only on YM2612 mode
    .debug_view     (              )
);

endmodule
