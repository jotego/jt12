`timescale 1ns / 1ps


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
	Date: 14-2-2017	

*/

module jt12_clk(
	input		rst,
	input		clk,
	
	input		set_n6,
	input		set_n3,
	input		set_n2,
	
	output		clk_int,
	output	reg rst_int
);

reg	clk_n2, clk_n3, clk_n6;

// Dirty clock mux, might generate glitches:
//assign clk_int = (set_n6&clk_n6) | (set_n3&clk_n3) | (set_n2&clk_n2);
assign clk_int = clk_n6;
//always @(posedge clk_n6 or posedge rst)
//	clk_int <= rst ? 1'b0 : ~clk_int;

// n=2
// Generate internal clock and synchronous reset for it.
reg	rst_int_aux;

always @(posedge clk or posedge rst) 
	clk_n2 	<= rst ? 1'b0 : ~clk_n2;

always @(posedge clk_n6 or posedge rst) 
	if( rst ) begin
		rst_int_aux	<= 1'b1;
		rst_int		<= 1'b1;
	end
	else begin
		rst_int_aux	<= 1'b0;
		rst_int		<= rst_int_aux;
	end

// n=3

reg A,B,C;

always @(posedge clk) 
	if( rst ) {A,B} <= 2'b0;
	else {A,B} <= {~A & ~B, A};


always @(negedge clk)
	C <= rst ? 1'b0 : B;
	
always @(*)
	clk_n3 <= C | B;
	
// n=6

always @(posedge clk_n3 or posedge rst)
	clk_n6 	<= rst ? 1'b0 : ~clk_n6;


endmodule
