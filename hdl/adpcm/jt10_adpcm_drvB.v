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

module jt10_adpcm_drvB(
    input           rst_n,
    input           clk,
    input           cen,      // 8MHz cen
    input           cen55,    // clk & cen = 55 kHz

    // Control
    input           acmd_on_b,  // Control - Process start, Key On
    input           acmd_rep_b, // Control - Repeat
    input           acmd_rst_b, // Control - Reset
    input    [ 1:0] alr_b,      // Left / Right
    input    [15:0] astart_b,   // Start address
    input    [15:0] aend_b,     // End   address
    input    [15:0] adeltan_b,  // Delta-N
    input    [ 7:0] aeg_b,      // Envelope Generator Control
    // memory
    output   [23:0] addr,
    input    [ 7:0] data,

    output signed [15:0]  pcm55_l,
    output signed [15:0]  pcm55_r
);

wire nibble_sel;
wire adv;           // advance to next reading

jt10_adpcmb_cnt u_cnt(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen55           ),
    .delta_n     ( adeltan_b       ),
    .clr         ( acmd_rst_b      ),
    .on          ( acmd_on_b       ),
    .astart      ( astart_b        ),
    .aend        ( aend_b          ),
    .arepeat     ( acmd_rep_b      ),
    .addr        ( addr            ),
    .nibble_sel  ( nibble_sel      ),
    .adv         ( adv             )
);

wire cen_dec;

jt10_cen_burst #(.cntmax(3'd6),.cntw(3))u_burst(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .start       ( adv             ),
    .cen_out     ( cen_dec         )
);

reg [3:0] din;

always @(posedge clk) din <= !nibble_sel ? data[7:4] : data[3:0];

wire signed [15:0] pcmdec;

jt10_adpcm u_decoder(
    .rst_n  ( rst_n          ),
    .clk    ( clk            ),
    .cen    ( cen_dec        ),
    .data   ( din            ),
    .chon   ( acmd_on_b      ),
    .pcm    ( pcmdec         )
);

// temporary assignment until linear interpolation is added
assign pcm55_l = alr_b[1] ? pcmdec : 16'd0;
assign pcm55_r = alr_b[0] ? pcmdec : 16'd0;

endmodule // jt10_adpcm_drvB