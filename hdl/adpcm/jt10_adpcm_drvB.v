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
    input           cen55,    // clk & cen55  =  55 kHz
    input           cen333,   // clk &c en333 = 333 kHz
    // Control
    input           acmd_on_b,  // Control - Process start, Key On
    input           acmd_rep_b, // Control - Repeat
    input           acmd_rst_b, // Control - Reset
    input    [ 1:0] alr_b,      // Left / Right
    input    [15:0] astart_b,   // Start address
    input    [15:0] aend_b,     // End   address
    input    [15:0] adeltan_b,  // Delta-N
    input    [ 7:0] aeg_b,      // Envelope Generator Control
    output          flag,
    input           clr_flag,
    // memory
    output   [23:0] addr,
    input    [ 7:0] data,
    output          roe_n,

    output reg signed [15:0]  pcm55_l,
    output reg signed [15:0]  pcm55_r
);

wire nibble_sel;
wire adv;           // advance to next reading
reg [1:0] adv2;

always @(posedge clk) begin
    roe_n <= ~adv;
    adv2 <= {adv2[0], adv }; // give some time to get the data from memory
end


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
    // Flag control
    .clr_flag    ( clr_flag        ),
    .flag        ( flag            ),
    .adv         ( adv             )
);

wire cen_dec;

jt10_cen_burst #(.cntmax(3'd5),.cntw(3))u_burst(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .start       ( adv2[1]         ),
    .start_cen   ( cen55           ),
    .cen_out     ( cen_dec         )
);

reg [3:0] din;

always @(posedge clk) din <= !nibble_sel ? data[7:4] : data[3:0];

wire signed [15:0] pcmdec, pcmgain;

jt10_adpcmb u_decoder(
    .rst_n  ( rst_n          ),
    .clk    ( clk            ),
    //.cen    ( cen_dec        ),
    .cen    ( cen333         ),
    .adv    ( adv & cen55    ),
    .data   ( din            ),
    .chon   ( acmd_on_b      ),
    .pcm    ( pcmdec         )
);

reg signed [15:0] pcmlast, delta_x;
reg signed [16:0] pre_dx;
reg start_div=1'b0;
reg [3:0] deltan, pre_dn;

always @(posedge clk) if(cen55) begin
    if ( adv2[1] )
        pre_dn  <= 'd1;
    else
        pre_dn <= pre_dn + 1;
end

reg signed [15:0] pcminter;
wire [15:0] step;

always @(posedge clk) if(cen55) begin
    if(adv2[1]) begin
        pre_dx <= { pcmdec[15], pcmdec } - { pcmlast[15], pcmlast };        
        pcmlast <= pcmdec;
        deltan  <= pre_dn;
        pcminter <= pcmdec;
    end
    else pcminter <= pcmdec + step;
end

always @(posedge clk) if(cen) begin
    delta_x <= pre_dx[16] ? ~pre_dx[15:0]+1 : pre_dx[15:0];
    start_div <= adv2[1];
end


jt10_adpcm_div #(.dw(16)) u_div(
    .rst_n  ( rst_n       ),
    .clk    ( clk         ),
    .cen    ( cen         ),
    .start  ( start_div & cen55  ),
    .a      ( delta_x     ),
    .b      ( {12'd0, deltan }   ),
    .d      ( step        ),
    .r      (             )
);



jt10_adpcmb_gain u_gain(
    .rst_n  ( rst_n          ),
    .clk    ( clk            ),
    .cen55  ( cen55          ),
    .tl     ( aeg_b          ),
    .pcm_in ( pcmdec         ),
    .pcm_out( pcmgain        )
);

always @(posedge clk) if(cen55) begin
    pcm55_l <= alr_b[1] ? pcmgain : 16'd0;
    pcm55_r <= alr_b[0] ? pcmgain : 16'd0;
end

endmodule // jt10_adpcm_drvB