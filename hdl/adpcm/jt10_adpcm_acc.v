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

// Adds all 6 channels and apply linear interpolation to rise
// sampling frequency to 55.5 kHz

module jt10_adpcm_acc(
    input           rst_n,
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [2:0]   ch,
    input      signed [15:0] pcm_in,    // 18.5 kHz
    output reg signed [15:0] pcm_out    // 55.5 kHz
);

wire signed [17:0] pcmin_long = { {2{pcm_in[15]}}, pcm_in };
reg  signed [17:0] acc, next, pcm_full;
reg  signed [17:0] step;

wire signed [17:0] diff = pcm_full - acc;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        step <= 'd0;
        pcm_full <= 18'd0;
        acc <= 18'd0;
    end else if(cen) begin
        acc <= ch==3'd0 ? pcmin_long : ( pcmin_long + acc );
        if( ch == 3'd0 ) begin
            // step = diff * (1/4+1/16+1/64+1/128)
            step <= {{2{diff[17]}},diff[17:2]} // 1 / 4 
                + {{4{diff[17]}},diff[17:5]}   // 1 / 16 
                + {{6{diff[17]}},diff[17:7]}   // 1 / 64
                + {{7{diff[17]}},diff[17:8]};  // 1 / 128
        end
        pcm_full <= pcm_full + step;
        if( ^pcm_full[17:15] ) // overflow
            pcm_out <= pcm_full[17] ? 16'h8000 : 16'h0; // saturate
        else
            pcm_out <= pcm_full[15:0];
    end

endmodule // jt10_adpcm_acc