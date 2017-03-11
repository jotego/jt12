/*  This file is part of JT12.

    JT12 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT12 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT12.  If not, see <http://www.gnu.org/licenses/>.

	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: March, 7th 2017
	*/

`timescale 1ns / 1ps

module jt12_fir
#(parameter data_width=9, extra=3)
(
	input	clk,	// Use clk_out from jt12, this is x24 higher than
	input	rst,
	input	sample,
	input	signed [data_width-1:0] left_in,
	input	signed [data_width-1:0] right_in,
	output	reg signed [data_width*2+1:0] left_out,
	output	reg signed [data_width*2+1:0] right_out,
	output	reg sample_out
);

parameter coeff_width=9;
parameter stages=73;
parameter addr_width=7;

`include "jt12_fir.vh"


initial begin
        coeff[0] <= -9'd0;
        coeff[1] <= -9'd1;
        coeff[2] <= -9'd1;
        coeff[3] <= -9'd2;
        coeff[4] <= -9'd3;
        coeff[5] <= -9'd3;
        coeff[6] <= -9'd4;
        coeff[7] <= -9'd4;
        coeff[8] <= -9'd3;
        coeff[9] <= -9'd1;
        coeff[10] <= 9'd1;
        coeff[11] <= 9'd3;
        coeff[12] <= 9'd7;
        coeff[13] <= 9'd10;
        coeff[14] <= 9'd12;
        coeff[15] <= 9'd13;
        coeff[16] <= 9'd12;
        coeff[17] <= 9'd9;
        coeff[18] <= 9'd3;
        coeff[19] <= -9'd5;
        coeff[20] <= -9'd14;
        coeff[21] <= -9'd24;
        coeff[22] <= -9'd33;
        coeff[23] <= -9'd40;
        coeff[24] <= -9'd43;
        coeff[25] <= -9'd39;
        coeff[26] <= -9'd29;
        coeff[27] <= -9'd12;
        coeff[28] <= 9'd13;
        coeff[29] <= 9'd44;
        coeff[30] <= 9'd80;
        coeff[31] <= 9'd119;
        coeff[32] <= 9'd157;
        coeff[33] <= 9'd192;
        coeff[34] <= 9'd222;
        coeff[35] <= 9'd243;
        coeff[36] <= 9'd255;
end

endmodule
