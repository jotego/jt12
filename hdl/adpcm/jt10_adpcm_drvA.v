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
    input           cen,    // clk & cen must be 111 kHz
    input           zero,

    output  [19:0]  addr,  // real hardware has 10 pins multiplexed through RMPX pin
    output  [3:0]   bank,
    output  reg     roe_n, // ADPCM-A ROM output enable

    // Control Registers
    input   [5:0]   atl,        // ADPCM Total Level
    input   [7:0]   lracl_in,
    input   [2:0]   cur_ch, // Channel count follows YM2612 way
    input   [11:0]  addr_in,

    input   [2:0]   up_lracl,
    input   [2:0]   up_start,
    input   [2:0]   up_end,

    input   [7:0]   aon_cmd,    // ADPCM ON equivalent to key on for FM

    input   [7:0]   datain,

    output signed [15:0]  pcm55_l,
    output signed [15:0]  pcm55_r
);

wire [19:0] cnt0, cnt1, cnt2, cnt3, cnt4, cnt5;
wire [5:0] sel; // use upper or lower nibble of input byte
reg  [5:0] aon, aoff;
reg  [3:0] data;
wire signed [15:0] pcmdec;
reg nibble_sel;

assign roe_n = 1'b1;

always @(*)
    case( cur_ch )
        3'b0_00:   nibble_sel = sel[5];
        3'b0_01:   nibble_sel = sel[0];
        3'b0_10:   nibble_sel = sel[1];
        3'b1_00:   nibble_sel = sel[2];
        3'b1_01:   nibble_sel = sel[3];
        3'b1_10:   nibble_sel = sel[4];
        default:   nibble_sel = 1'b0;
    endcase

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        data <= 4'd0;
    end else if(cen) begin
        data <= nibble_sel ? datain[7:4] : datain[3:0];
    end

always @(posedge clk or negedge rst_n) 
    if( !rst_n ) begin
        addr <= 20'd0;
    end else begin  // no clock enable for address setting
        case( cur_ch )
            3'b0_00: begin addr <= cnt0; roe_n <= ~aon[0]; end
            3'b0_01: begin addr <= cnt1; roe_n <= ~aon[1]; end
            3'b0_10: begin addr <= cnt2; roe_n <= ~aon[2]; end
            3'b1_00: begin addr <= cnt3; roe_n <= ~aon[3]; end
            3'b1_01: begin addr <= cnt4; roe_n <= ~aon[4]; end
            3'b1_10: begin addr <= cnt5; roe_n <= ~aon[5]; end
            default: roe_n <= 1'b1;
        endcase
        aon  <= {6{!aon_cmd[7]}} & aon_cmd[5:0];
        aoff <= {6{ aon_cmd[7]}} & aon_cmd[5:0];
    end

reg [5:0] up_start_dec, up_end_dec;

always @(posedge clk or negedge rst_n) 
    if( !rst_n ) begin
        up_start_dec <= 6'd0;
        up_end_dec   <= 6'd0;
    end else begin  // no clock enable for address setting
        case( up_start )
            3'd0: up_start_dec <= 6'b000_001;
            3'd1: up_start_dec <= 6'b000_010;
            3'd2: up_start_dec <= 6'b000_100;
            3'd3: up_start_dec <= 6'b001_000;
            3'd4: up_start_dec <= 6'b010_000;
            3'd5: up_start_dec <= 6'b100_000;
            default: up_start_dec <= 6'd0;
        endcase
        case( up_end )
            3'd0: up_end_dec <= 6'b000_001;
            3'd1: up_end_dec <= 6'b000_010;
            3'd2: up_end_dec <= 6'b000_100;
            3'd3: up_end_dec <= 6'b001_000;
            3'd4: up_end_dec <= 6'b010_000;
            3'd5: up_end_dec <= 6'b100_000;
            default: up_end_dec <= 6'd0;
        endcase
    end

reg up_lracl_dec;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        up_lracl_dec <= 1'b0;
    end else if(cen) begin
        case( up_lracl )
            3'd0:   up_lracl_dec <= cur_ch == 3'b0_00;
            3'd1:   up_lracl_dec <= cur_ch == 3'b0_01;
            3'd2:   up_lracl_dec <= cur_ch == 3'b0_10;
            3'd3:   up_lracl_dec <= cur_ch == 3'b1_00;
            3'd4:   up_lracl_dec <= cur_ch == 3'b1_01;
            3'd5:   up_lracl_dec <= cur_ch == 3'b1_10;
            default:up_lracl_dec <= 1'b0;
        endcase
    end

jt10_adpcm_cnt u_cnt0(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[0] ),
    .up_end      ( up_end_dec[0]   ),
    .aon         ( aon[0]          ),
    .aoff        ( aoff[0]         ),
    .cnt         ( cnt0            ),
    .sel         ( sel[0]          )
);

jt10_adpcm_cnt u_cnt1(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[1] ),
    .up_end      ( up_end_dec[1]   ),
    .aon         ( aon[1]          ),
    .aoff        ( aoff[1]         ),
    .cnt         ( cnt1            ),
    .sel         ( sel[1]          )
);

jt10_adpcm_cnt u_cnt2(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[2] ),
    .up_end      ( up_end_dec[2]   ),
    .aon         ( aon[2]          ),
    .aoff        ( aoff[2]         ),
    .cnt         ( cnt2            ),
    .sel         ( sel[2]          )
);

jt10_adpcm_cnt u_cnt3(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[3] ),
    .up_end      ( up_end_dec[3]   ),
    .aon         ( aon[3]          ),
    .aoff        ( aoff[3]         ),
    .cnt         ( cnt3            ),
    .sel         ( sel[3]          )
);

jt10_adpcm_cnt u_cnt4(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[4] ),
    .up_end      ( up_end_dec[4]   ),
    .aon         ( aon[4]          ),
    .aoff        ( aoff[4]         ),
    .cnt         ( cnt4            ),
    .sel         ( sel[4]          )
);

jt10_adpcm_cnt u_cnt5(
    .rst_n       ( rst_n           ),
    .clk         ( clk             ),
    .cen         ( cen             ),
    .addr_in     ( addr_in         ),
    .cur_ch      ( cur_ch          ),
    .up_start    ( up_start_dec[5] ),
    .up_end      ( up_end_dec[5]   ),
    .aon         ( aon[5]          ),
    .aoff        ( aoff[5]         ),
    .cnt         ( cnt5            ),
    .sel         ( sel[5]          )
);

jt10_adpcm u_decoder(
    .rst_n  ( rst_n     ),
    .clk    ( clk       ),
    .cen    ( cen       ),
    .data   ( data      ),
    .pcm    ( pcmdec    )
);

wire signed [15:0] pcm18_l, pcm18_r;

jt10_adpcm_gain u_gain(
    .rst_n  ( rst_n         ),
    .clk    ( clk           ),
    .cen    ( cen           ),
    .lracl  ( lracl_in      ),
    .atl    ( atl           ),        // ADPCM Total Level
    .up     ( up_lracl_dec  ),
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