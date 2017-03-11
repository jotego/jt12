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

module jt12_fir_ram 
#(parameter data_width=8, parameter addr_width=7)
(
	input [(data_width-1):0] data,
	input [(addr_width-1):0] addr,
	input we, clk,
	output [(data_width-1):0] q
);

(* ramstyle = "M-RAM, no_rw_check" *) reg [data_width-1:0] ram[2**addr_width-1:0];

	always @ (posedge clk)
		if (we)
			ram[addr] <= data;
	assign q = ram[addr];
endmodule
