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
    Date: 15-11-2018

*/


// Use for YM2203
// no left/right channels
// Full operator resolution and 18-bit accumulation, as in YM2203.
// Clip to the signed 16-bit sample range only when loading the sample.

module jt03_acc
(
    input               rst,
    input               clk,
    input               clk_en /* synthesis direct_enable */,
    input signed [13:0] op_result,
    input               s1_enters,
    input               s2_enters,
    input               s3_enters,
    input               s4_enters,
    input               zero,
    input   [2:0]       alg,
    // combined output
    output signed [15:0] snd
);

reg sum_en;

always @(*) begin
    case ( alg )
        default: sum_en = s4_enters;
        3'd4: sum_en = s2_enters | s4_enters;
        3'd5,3'd6: sum_en = ~s1_enters;        
        3'd7: sum_en = 1'b1;
    endcase
end

reg signed [17:0] acc;
reg signed [15:0] sample;
wire signed [17:0] current;

assign current = sum_en ? {{4{op_result[13]}},op_result} : 18'd0;
assign snd = sample;

always @(posedge clk) if( clk_en ) begin
    acc <= zero ? current : acc+current;
    if( zero ) begin
        sample <= acc > 18'sd32767  ? 16'sh7fff :
                  acc < -18'sd32768 ? 16'sh8000 : acc[15:0];
    end
end

endmodule
