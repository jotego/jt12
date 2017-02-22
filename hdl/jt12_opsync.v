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
	Date: 27-1-2017	

*/

module jt12_opsync(
	input				rst,
    input				clk,

	input		[4:0]	next,
	output	reg			s1_enters,
	output	reg			s2_enters,
	output	reg			s3_enters,
	output	reg			s4_enters
);


always @(posedge clk)
	if( rst ) begin
		s1_enters = 1'b1;
		s3_enters = 1'b0;
		s2_enters = 1'b0;
		s4_enters = 1'b0;		
	end
	else begin
		s1_enters <= next < 5'd6;
		s3_enters <= next >= 5'd6  && next < 5'd12;
		s2_enters <= next >= 5'd12 && next < 5'd18;
		s4_enters <= next >= 5'd18;
	end
    
endmodule
