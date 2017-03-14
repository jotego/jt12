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

module jt12_dac #(parameter width=12)
(
	input	clk,
    input	rst,
    input	signed	[width-1:0] din,
    output	dout
);

reg [width-1:0] unsigned_din;
reg [width:0] acc;

assign dout = acc[width];

always @(posedge clk) 
if( rst ) begin
	acc <= {(width+1){1'b0}};
end
else begin
	unsigned_din <= { ~din[width-1], din[width-2:0] };
	acc <= unsigned_din + acc[width-1:0];
end

endmodule
