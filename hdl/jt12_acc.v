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
    
    Each channel can use the full range of the DAC as they do not
    get summed in the real chip.

    Operator data is summed up without adding extra bits. This is
    the case of real YM3438, which was used on Megadrive 2 models.


*/

`timescale 1ns / 1ps

module jt12_acc
(
    input               rst,
    input               clk,
    input               clk_en,
    input signed [8:0]  op_result,
    input        [ 1:0] rl,
    input               limiter_en, // enables the limiter on
    // the accumulator to prevent overfow. 
    // I reckon that:
    // YM2612 had a limiter
    // YM3438 did not
    // note that the order changes to deal 
    // with the operator pipeline delay
    input               zero,
    input               s1_enters,
    input               s2_enters,
    input               s3_enters,
    input               s4_enters,
    input               ch6op,
    input   [2:0]       alg,
    input               pcm_en, // only enabled for channel 6
    input   [8:0]       pcm,
    // combined output
    output signed   [11:0]  left,
    output signed   [11:0]  right,
    // multiplexed output
    output signed   [8:0]   mux_left,
    output signed   [8:0]   mux_right,  
    output          mux_sample
);

parameter num_ch=6;

reg signed [11:0] pre_left, pre_right;

reg sum_en;

always @(*) begin
    case ( alg )
        default: sum_en = s4_enters;
        3'd4: sum_en = s2_enters | s4_enters;
        3'd5,3'd6: sum_en = ~s1_enters;        
        3'd7: sum_en = 1'b1;
    endcase
end

wire use_pcm = ch6op && pcm_en;
wire sum_or_pcm = sum_en | use_pcm;
wire left_en = rl[1];
wire right_en= rl[0];
wire [8:0] acc_input =  use_pcm ? { ~pcm[8], pcm[7:0] } : op_result;

// Continuous output
jt12_single_acc #(.win(9),.wout(12)) u_left(
    .clk        ( clk            ),
    .clk_en     ( clk_en         ),
    .op_result  ( acc_input      ),
    .sum_en     ( sum_or_pcm & left_en ),
    .zero       ( zero           ),
    .snd        ( left           )
);


jt12_single_acc #(.win(9),.wout(12)) u_right(
    .clk        ( clk            ),
    .clk_en     ( clk_en         ),
    .op_result  ( acc_input      ),
    .sum_en     ( sum_or_pcm & right_en ),
    .zero       ( zero           ),
    .snd        ( right          )
);

// Multiplexed output

assign mux_left = 9'd0;
assign mux_right = 9'd0;
assign mux_sample = 1'b0;

endmodule
