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

// YM2610
// ADPCM inputs
// Full OP resolution
// No PCM
// 4 OP channels

// ADPCM-A input is added for the time assigned to FM channel 0_10 (i.e. 3)

module jt10_acc(
    input               clk,
    input               clk_en,
    input signed [13:0] op_result,
    input        [ 1:0] rl,
    input               zero,
    input               s1_enters,
    input               s2_enters,
    input               s3_enters,
    input               s4_enters,
    input       [2:0]   cur_ch,
    input   [2:0]       alg,
    input signed [15:0] adpcma_l,
    input signed [15:0] adpcma_r,
    // combined output
    output reg signed   [15:0]  left,
    output reg signed   [15:0]  right
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

wire left_en = rl[1];
wire right_en= rl[0];
wire signed [15:0] opext = { {2{op_result[13]}}, op_result };
reg  signed [15:0] acc_input_l, acc_input_r;
reg acc_en_l, acc_en_r;

always @(*)
    case(cur_ch)
        3'b0_10: begin
            acc_input_l = adpcma_l;
            acc_input_r = adpcma_r;
            acc_en_l    = 1'b1;
            acc_en_r    = 1'b1;
        end
        default: begin
            acc_input_l = opext;
            acc_input_r = opext;
            acc_en_l    = sum_en & left_en;
            acc_en_r    = sum_en & right_en;
        end
    endcase

// Continuous output

jt12_single_acc #(.win(16),.wout(16)) u_left(
    .clk        ( clk            ),
    .clk_en     ( clk_en         ),
    .op_result  ( acc_input_l    ),
    .sum_en     ( acc_en_l       ),
    .zero       ( zero           ),
    .snd        ( left           )
);

jt12_single_acc #(.win(16),.wout(16)) u_right(
    .clk        ( clk            ),
    .clk_en     ( clk_en         ),
    .op_result  ( acc_input_r    ),
    .sum_en     ( acc_en_r       ),
    .zero       ( zero           ),
    .snd        ( right          )
);

endmodule
