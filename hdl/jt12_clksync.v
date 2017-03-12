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

module jt12_clksync(
	input			rst,
	input			clk,
(* direct_enable = 1 *)	input			clk_en,

	input	[7:0]	din,
	input	[1:0]	addr,
	input			busy_mmr,
	input			flag_A,
	input			flag_B,
	input			cs_n,
	input			wr_n,
	
	output	reg		clk_fm_en,
	output	reg		rst_int,
	output	reg [7:0]	din_s,
	output	reg [1:0]	addr_s,
	output	[7:0]	dout,
	output	reg		write
);

reg [2:0] cnt;
always @(negedge clk) if(clk_en) begin
	if( rst )
		cnt <= 3'd0;
	else
		cnt <= (cnt==3'd5) ? 3'd0 : cnt+1'b1;
end

always @(negedge clk)
	clk_fm_en <= clk_en && (cnt==3'd0);	

// reset generation
reg rst_aux, rst_aux0;

always @(posedge clk)
	{rst_aux,rst_aux0} <= { rst_aux0,rst };
	
always @(posedge clk or posedge rst_aux) 
	if( rst_aux ) begin
		rst_int <= 1'b1;
	end
	else if( clk_fm_en ) begin
		rst_int <= 1'b0;
	end


/*
jt12_clk u_clkgen(
	.rst		( rst		),
	.clk		( clk		),
	
	.set_n6		( set_n6	),
	.set_n3		( set_n3	),
	.set_n2		( set_n2	),
	
	.clk_int	( clk_int	),
	.rst_int	( rst_int	)
);
*/

reg		busy;
reg	[1:0] busy_mmr_sh;

//reg		flag_B_s, flag_A_s;
assign 	dout = { busy, 5'h0, flag_B, flag_A };
/*
always @(posedge clk ) 
	{ flag_B_s, flag_A_s } <= { flag_B, flag_A };
*/
//assign	write = !cs_n && !wr_n;

wire		write_raw = !cs_n && !wr_n;

reg	[7:0]	din_copy;
reg	[1:0]	addr_copy;
reg			write_copy;

always @(posedge clk) if(clk_en) begin : cpu_interface
	if( rst ) begin
		busy		<= 1'b0;
		addr_copy	<= 2'b0;
		din_copy	<= 8'd0;
		write_copy	<= 1'b0;
	end
	else begin
		busy_mmr_sh <= { busy_mmr_sh[0], busy_mmr };
		if( write_raw && !busy ) begin
			busy 		<= 1'b1;
			write_copy	<= 1'b1;
			addr_copy	<= addr;
			din_copy	<= din;
		end
		else begin
			if( busy_mmr ) write_copy	<= 1'b0;
			if( busy && busy_mmr_sh==2'b10 ) busy <= 1'b0;
		end
	end
end

always @(posedge clk ) if(clk_fm_en)
	{ write, addr_s, din_s } <= { write_copy, addr_copy, din_copy };

endmodule
