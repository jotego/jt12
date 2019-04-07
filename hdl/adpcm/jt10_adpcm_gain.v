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

module jt10_adpcm_gain(
    input           rst_n,
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input           div3,
    input   [5:0]   atl,        // ADPCM Total Level
    // Gain update
    input   [7:0]   lracl,
    input   [2:0]   up_ch,
    // Data
    input signed [15:0] pcm_in,
    output reg signed [15:0] pcm_l,
    output reg signed [15:0] pcm_r
);

reg [7:0] lracl1, lracl2, lracl3, lracl4, lracl5, lracl6;

reg  [9:0] lin_2b, lin3, lin4;
reg  [6:0] db2, db3;
reg signed [31:0] pcm5;
reg signed [15:0] pcm6;


reg [3:0] sh3, sh4, sh5;

reg [5:0] up_ch_dec;
always @(*)
    case(up_ch)
        3'd0: up_ch_dec = 6'b000_001;
        3'd1: up_ch_dec = 6'b000_010;
        3'd2: up_ch_dec = 6'b000_100;
        3'd3: up_ch_dec = 6'b001_000;
        3'd4: up_ch_dec = 6'b010_000;
        3'd5: up_ch_dec = 6'b100_000;
        default: up_ch_dec = 6'd0;
    endcase // up_addr

always @(*)
    case( db2[2:0] )
        3'd0: lin_2b = 10'd512;
        3'd1: lin_2b = 10'd470;
        3'd2: lin_2b = 10'd431;
        3'd3: lin_2b = 10'd395;
        3'd4: lin_2b = 10'd362;
        3'd5: lin_2b = 10'd332;
        3'd6: lin_2b = 10'd305;
        3'd7: lin_2b = 10'd280;
    endcase

wire signed [15:0] lin4s = {6'b0,lin4};
wire signed [15:0] pcm5b = pcm5[24:9];
reg [5:0] cur_ch;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        lracl1  <= 8'd0; lracl2 <= 8'd0;
        lracl3  <= 8'd0; lracl4 <= 8'd0;
        lracl5  <= 8'd0; lracl6 <= 8'd0;
        db2     <= 'd0;
        db3     <= 'd0;
        pcm5    <= 'd0;
        pcm_l   <= 'd0;
        pcm_r   <= 'd0;
        cur_ch  <= 6'h20;
    end else if(cen) begin
        cur_ch <= { cur_ch[4:0], cur_ch[5] };

        // I
        lracl2  <= up_ch_dec == cur_ch ? lracl : lracl1;
        db2     <= { 1'b0, ~lracl1[5:0] } + {1'b0, ~atl};
        // II
        lracl3  <= lracl2;
        lin3    <= lin_2b;
        sh3     <= db2[6:3];
        // III
        lracl4  <= lracl3;
        lin4    <= sh3[3] ? 10'h0 : lin3;
        sh4     <= sh3;
        // IV: new data is accepted here
        lracl5  <= lracl4;
        pcm5    <= pcm_in * lin4s; // multiplier
        sh5     <= sh4;
        // V
        pcm6    <= pcm5b >>> sh5;
        lracl6  <= lracl5;
        // VI close the loop
        lracl1 <= lracl6;
        if(div3) pcm_l  <= lracl6[7] ? pcm6 : 16'd0;
        if(div3) pcm_r  <= lracl6[6] ? pcm6 : 16'd0;
    end

endmodule // jt10_adpcm_gain
