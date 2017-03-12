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

module jt12_fir4
#(parameter data_width=9, output_width=12)
(
	input	clk,	// Use clk_out from jt12, this is x24 higher than
	input	rst,
	input	sample,
	input	signed [data_width-1:0] left_in,
	input	signed [data_width-1:0] right_in,
	output	reg signed [output_width-1:0] left_out,
	output	reg signed [output_width-1:0] right_out,
	output	reg sample_out
);

parameter coeff_width=9;
parameter stages=11;
parameter addr_width=4;
parameter acc_extra=-1;

`include "jt12_fir.vh"

initial begin
        coeff[0] <= 9'd19;
        coeff[1] <= 9'd42;
        coeff[2] <= 9'd100;
        coeff[3] <= 9'd172;
        coeff[4] <= 9'd232;
        coeff[5] <= 9'd255;
end

endmodule
