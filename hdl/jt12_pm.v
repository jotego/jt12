/*  This file is part of jt12.

    jt12 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    jt12 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with jt12.  If not, see <http://www.gnu.org/licenses/>.
	
	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: 14-10-2018
	*/

`timescale 1ns / 1ps

module jt12_pm (
	input [4:0] lfo_mod,
	input [10:0] fnum,
	input [2:0] pms,
	output reg signed [7:0] pm_offset
);


reg [7:0] pm_unsigned;
reg [4:0] pm_base;

wire [2:0] index = lfo_mod[3] ? (~lfo_mod[2:0]) : lfo_mod[2:0];

always @(*) begin
	casez ( {pms, index} )
		{3'd0, 3'd? }: pm_base = 5'd0;
		{3'd?, 3'd0 }: pm_base = 5'd0;
		{3'd?, 3'd1 }: pm_base = 5'd0;

		{3'd1, 3'd2 }: pm_base = 5'd0;
		{3'd1, 3'd3 }: pm_base = 5'd0;
		{3'd1, 3'd4 }: pm_base = 5'd1;
		{3'd1, 3'd5 }: pm_base = 5'd1;
		{3'd1, 3'd6 }: pm_base = 5'd1;
		{3'd1, 3'd7 }: pm_base = 5'd1;

		{3'd2, 3'd2 }: pm_base = 5'd0;
		{3'd2, 3'd3 }: pm_base = 5'd1;
		{3'd2, 3'd4 }: pm_base = 5'd1;
		{3'd2, 3'd5 }: pm_base = 5'd1;
		{3'd2, 3'd6 }: pm_base = 5'd2;
		{3'd2, 3'd7 }: pm_base = 5'd2;

		{3'd3, 3'd2 }: pm_base = 5'd1;
		{3'd3, 3'd3 }: pm_base = 5'd1;
		{3'd3, 3'd4 }: pm_base = 5'd2;
		{3'd3, 3'd5 }: pm_base = 5'd2;
		{3'd3, 3'd6 }: pm_base = 5'd3;
		{3'd3, 3'd7 }: pm_base = 5'd3;

		{3'd4, 3'd2 }: pm_base = 5'd1;
		{3'd4, 3'd3 }: pm_base = 5'd2;
		{3'd4, 3'd4 }: pm_base = 5'd2;
		{3'd4, 3'd5 }: pm_base = 5'd2;
		{3'd4, 3'd6 }: pm_base = 5'd3;
		{3'd4, 3'd7 }: pm_base = 5'd4;

		{3'd5, 3'd2 }: pm_base = 5'd2;
		{3'd5, 3'd3 }: pm_base = 5'd3;
		{3'd5, 3'd4 }: pm_base = 5'd4;
		{3'd5, 3'd5 }: pm_base = 5'd4;
		{3'd5, 3'd6 }: pm_base = 5'd5;
		{3'd5, 3'd7 }: pm_base = 5'd6;

		{3'd6, 3'd2 }: pm_base = 5'd4;
		{3'd6, 3'd3 }: pm_base = 5'd6;
		{3'd6, 3'd4 }: pm_base = 5'd8;
		{3'd6, 3'd5 }: pm_base = 5'd8;
		{3'd6, 3'd6 }: pm_base = 5'd10;
		{3'd6, 3'd7 }: pm_base = 5'd12;

		{3'd7, 3'd2 }: pm_base = 5'd8;
		{3'd7, 3'd3 }: pm_base = 5'd12;
		{3'd7, 3'd4 }: pm_base = 5'd16;
		{3'd7, 3'd5 }: pm_base = 5'd16;
		{3'd7, 3'd6 }: pm_base = 5'd20;
		{3'd7, 3'd7 }: pm_base = 5'd24;
	endcase

	casez( fnum[10:4] )
		7'b1??_????: pm_unsigned = { 1'b0, pm_base, 2'd0 };
		7'b01?_????: pm_unsigned = { 1'b0, pm_base, 1'd0 };
		7'b001_????: pm_unsigned = { 2'b0, pm_base };
		7'b000_1???: pm_unsigned = { 3'b0, pm_base[4:1] };
		7'b000_01??: pm_unsigned = { 4'b0, pm_base[4:2] };
		7'b000_001?: pm_unsigned = { 5'b0, pm_base[4:3] };
		7'b000_0001: pm_unsigned = { 6'b0, pm_base[4]   };
		default: pm_unsigned = 8'd0;
	endcase

	pm_offset = lfo_mod[4] ? (~pm_unsigned+8'd1) : pm_unsigned;
end // always @(*)

endmodule
