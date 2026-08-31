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

module jt10b_mixer(
    input               clk,
    input               cen,
    input signed [15:0] fm_in,
    input signed [15:0] adpcma_in,
    input signed [15:0] adpcmb_in,
    input        [ 9:0] psg_in,
    output reg signed [15:0] fm_out,
    output reg signed [15:0] snd_out
);

localparam signed [5:0] ADPCMA_GAIN = 6'sd29; // Q2: 29/4 = 7.25

wire signed [20:0] adpcma_mul;
wire signed [20:0] adpcma_gain;
wire signed [20:0] fm_ext, adpcmb_ext, psg_ext;
wire signed [20:0] fm_mix, snd_mix;

function signed [15:0] sat16;
    input signed [20:0] value;
    begin
        sat16 = (&value[20:15] | ~|value[20:15]) ? value[15:0] :
                value[20] ? 16'h8000 : 16'h7fff;
    end
endfunction

assign adpcma_mul  = adpcma_in * ADPCMA_GAIN;
assign adpcma_gain = adpcma_mul >>> 2;
assign fm_ext      = { {5{fm_in[15]}}, fm_in };
assign adpcmb_ext  = { {5{adpcmb_in[15]}}, adpcmb_in };
assign psg_ext     = { 5'd0, 1'b0, psg_in, 5'd0 };
assign fm_mix      = fm_ext + adpcma_gain + (adpcmb_ext >>> 1);
assign snd_mix     = fm_mix + psg_ext;

always @(posedge clk) if(cen) begin
    fm_out  <= sat16( fm_mix  );
    snd_out <= sat16( snd_mix );
end

endmodule
