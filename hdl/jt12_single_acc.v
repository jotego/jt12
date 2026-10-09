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
    Date: 27-1-2017 
    
*/

// Accumulates an arbitrary number of inputs. The default saturates the
// running sum; a wider accumulator clips only when loading the sample.
// Restart the sum when input "zero" is high.


module jt12_single_acc #(parameter 
        win=14, // input data width
        wout=16, // output data width
        wacc=wout // internal accumulator width
)(
    input                 clk,
    input                 clk_en /* synthesis direct_enable */,
    input [win-1:0]       op_result,
    input                 sum_en,
    input                 zero,
    output reg [wout-1:0] snd
);

// YM2203 uses win=14, wout=16, wacc=18
// for cut down resolution use win=9, wout=12
// wacc must be at least as wide as win and wout. With wacc>wout,
// accumulate without intermediate clipping and clip the output sample.

reg signed [wacc-1:0] next, acc, current;
reg overflow;

wire [wacc-1:0] plus_inf  = { 1'b0, {(wacc-1){1'b1}} };
wire [wacc-1:0] minus_inf = { 1'b1, {(wacc-1){1'b0}} };
wire signed [wacc-1:0] output_max = {{(wacc-wout){1'b0}},1'b0,{(wout-1){1'b1}}};
wire signed [wacc-1:0] output_min = {{(wacc-wout){1'b1}},1'b1,{(wout-1){1'b0}}};
wire [wout-1:0] sample_max = {1'b0,{(wout-1){1'b1}}};
wire [wout-1:0] sample_min = {1'b1,{(wout-1){1'b0}}};

always @(*) begin
    current = sum_en ? { {(wacc-win){op_result[win-1]}}, op_result } : {wacc{1'b0}};
    next = zero ? current : current + acc;
    overflow = !zero && 
        (current[wacc-1] == acc[wacc-1]) &&
        (acc[wacc-1]!=next[wacc-1]);
end

always @(posedge clk) if( clk_en ) begin
    acc <= wacc==wout && overflow ? (acc[wacc-1] ? minus_inf : plus_inf) : next;
    if(zero) snd <= acc > output_max ? sample_max :
                     acc < output_min ? sample_min : acc[wout-1:0];
end

endmodule // jt12_single_acc
