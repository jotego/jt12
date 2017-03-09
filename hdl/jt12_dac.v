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
	Date: March, 9th 2017
	*/

`timescale 1ns / 1ps

/*

	input sampling rate must be the same as clk frequency
    interpolation the input signal accordingly to get the
    right sampling rate

*/

module jt12_dac(
	input	clk,
    input	rst,
    input	signed	[19:0] din,
    output	reg	 dout
);

reg signed [21:0] sigma;
reg signed [22:0] sigma_unlim;
reg signed [21:0] delta, delta1, delta2, delta1x2;

always @(*) begin
	if( delta1[20] )
    	delta1x2 <= { delta1[21], {21{~delta1[21]}}};
    else
    	delta1x2 <= delta1<<<1;

	sigma_unlim <= din + delta2 + delta1x2;
    case( sigma_unlim[22:21] )
    	2'b01: sigma <= { 1'b0, {20{1'b1}}};
        2'b10: sigma <= { 1'b1, {20{1'b0}}};
        default sigma <= sigma_unlim[21:0];
    endcase
end

always @(posedge clk) begin
	dout <= sigma[20];
    delta1 <= sigma - { 1'b0, sigma[20], 20'd0 };
    delta2 <= delta1;
end

endmodule
