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

module jt10_adpcm_drvA(
    input           rst_n,
    input           clk,    // CPU clock
    input           cen,    // clk & cen = 333 kHz
    input           cen3,   // clk & cen = 111 kHz

    output  [19:0]  addr,  // real hardware has 10 pins multiplexed through RMPX pin
    output  [3:0]   bank,
    output  reg     roe_n, // ADPCM-A ROM output enable

    // Control Registers
    input   [5:0]   atl,        // ADPCM Total Level
    input   [7:0]   lracl_in,
    input   [2:0]   cur_ch, // Channel count follows YM2612 way
    input   [11:0]  addr_in,

    input   [2:0]   up_lracl,
    input           up_start,
    input           up_end,
    input   [2:0]   up_addr,

    input   [7:0]   aon_cmd,    // ADPCM ON equivalent to key on for FM

    input   [7:0]   datain,

    output signed [15:0]  pcm55_l,
    output signed [15:0]  pcm55_r
);

reg  [3:0] data;
wire signed [15:0] pcmdec;
wire nibble_sel;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        data <= 4'd0;
    end else if(cen) begin
        data <= nibble_sel ? datain[7:4] : datain[3:0];
    end

reg [ 5:0] up_start_sr, up_end_sr, aon_sr, aoff_sr;
reg [ 2:0] chlin;
reg [11:0] addr_in2;

reg [5:0] up_addr_dec;
always @(*)
    case(up_addr)
        3'd0: up_addr_dec = 6'b000_001;
        3'd1: up_addr_dec = 6'b000_010;
        3'd2: up_addr_dec = 6'b000_100;
        3'd3: up_addr_dec = 6'b001_000;
        3'd4: up_addr_dec = 6'b010_000;
        3'd5: up_addr_dec = 6'b100_000;
        default: up_addr_dec = 6'd0;
    endcase // up_addr

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        chlin <= 'd0;
        up_start_sr <= 'd0;
        up_end_sr   <= 'd0;
        aon_sr      <= 'd0;
        aoff_sr     <= 'd0;
    end else if(cen) begin
        addr_in2 <= addr_in; // delay one clock cycle to synchronize with up_*_sr registers
        chlin <= chlin==3'd5 ? 3'd0 : chlin + 3'd1;
        up_start_sr <= chlin==5 &&    up_start ?  up_addr_dec : { 1'b0, up_start_sr[5:1] };
        up_end_sr   <= chlin==5 &&      up_end ?  up_addr_dec : { 1'b0, up_end_sr[5:1] };
        aon_sr      <= chlin==5 && !aon_cmd[7] ? aon_cmd[5:0] : { 1'b0, aon_sr[5:1] };
        aoff_sr     <= chlin==5 &&  aon_cmd[7] ? aon_cmd[5:0] : { 1'b0, aoff_sr[5:1] };
    end

reg [2:0] div3;
always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        div3 <= 3'b1;
    end else if(cen) begin
        if(chlin==3'd5) div3 <= { div3[1:0], div3[2] };
    end


jt10_adpcm_cnt u_cnt(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .div3        ( cen3 ), //div3[0]         ),
    .addr_in     ( addr_in2        ),
    .up_start    ( up_start_sr[0]  ),
    .up_end      ( up_end_sr[0]    ),
    .aon         ( aon_sr[0]       ),
    .aoff        ( aoff_sr[0]      ),
    .addr_out    ( addr            ),
    .sel         ( nibble_sel      ),
    .roe_n       ( roe_n           )
);

reg chon;
always @(posedge clk) if(cen) chon <= ~roe_n;

jt10_adpcm u_decoder(
    .rst_n  ( rst_n     ),
    .clk    ( clk       ),
    .cen    ( cen3      ),
    .data   ( data      ),
    .chon   ( chon      ),
    .pcm    ( pcmdec    )
);

wire signed [15:0] pcm18_l, pcm18_r;

jt10_adpcm_gain u_gain(
    .rst_n  ( rst_n         ),
    .clk    ( clk           ),
    .cen    ( cen           ),
    .lracl  ( lracl_in      ),
    .atl    ( atl           ),        // ADPCM Total Level
    .up     ( 1'b0  ),
    .pcm_in ( pcmdec        ),
    .pcm_l  ( pcm18_l       ),
    .pcm_r  ( pcm18_r       )
);

jt10_adpcm_acc u_acc_left(
    .rst_n  ( rst_n     ),
    .clk    ( clk       ),
    .cen    ( cen       ),
    .cur_ch ( cur_ch    ),
    .pcm_in ( pcm18_l   ),    // 18.5 kHz
    .pcm_out( pcm55_l   )     // 55.5 kHz
);

jt10_adpcm_acc u_acc_right(
    .rst_n  ( rst_n     ),
    .clk    ( clk       ),
    .cen    ( cen       ),
    .cur_ch ( cur_ch    ),
    .pcm_in ( pcm18_r   ),    // 18.5 kHz
    .pcm_out( pcm55_r   )     // 55.5 kHz
);

endmodule // jt10_adpcm_drvA