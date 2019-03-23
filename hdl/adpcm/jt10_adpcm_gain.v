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
    input   [7:0]   lracl,
    input   [5:0]   atl,        // ADPCM Total Level
    input           we,
    input signed [15:0] pcm_in,
    output reg signed [15:0] pcm_l,
    output reg signed [15:0] pcm_r
);

reg [7:0] lracl1, lracl2, lracl3, lracl4, lracl5, lracl6;

wire [8:0] lin_gain3;
wire [9:0] lin_gain4;
reg  [6:0] db2, db3;
reg [25:0] pcm_mul5;
reg [15:0] pcm_mul6;

jt10_adpcm_dbrom u_rom(
    .clk    ( clk       ),
    .db     ( db2[5:0]  ),
    .lin    ( lin_gain3 )
);

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        lracl1 <= 8'd0; lracl2 <= 8'd0;
        lracl3 <= 8'd0; lracl4 <= 8'd0;
        lracl5 <= 8'd0; lracl6 <= 8'd0;
        db2 <= 'd0;
        db3 <= 'd0;
        pcm_mul5 <= 'd0;
        pcm_l    <= 'd0;
        pcm_r    <= 'd0;
    end else if(cen) begin
        // I
        lracl2  <= lracl1;
        db2     <= { 1'b0, ~lracl1[5:0] } + {1'b0, ~atl};
        // II
        lracl3  <= lracl2;
        db3     <= db2;
        // III
        lracl4 <= lracl3;
        lin_gain4 <=  db3==7'd0 ? 10'h200 : 
            ( db3[6] ? 10'h0 : { 1'b0, lin_gain3 } );
        // IV: new data is accepted here
        lracl5   <= we ? lracl : lracl4;
        pcm_mul5 <= pcm_in * lin_gain4; // multiplier
        // V
        pcm_mul6 <= pcm_mul5[25:10];
        lracl6   <= lracl5;
        // VI close the loop
        lracl1 <= lracl6;
        pcm_l  <= lracl6[7] ? pcm_mul6 : 16'd0;
        pcm_r  <= lracl6[6] ? pcm_mul6 : 16'd0;
    end

endmodule // jt10_adpcm_gain
