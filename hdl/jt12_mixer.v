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

module jt12_mixer(
	input	clk,	// use at least jt12 clk x 7 (i.e. 54MHz)
	input	rst,
	input	sample,
	input	[2:0] volume,
	input	signed [8:0] left_in,
	input	signed [8:0] right_in,
	input	[ 11:0]	psg,
	input	enable_psg,
	input	enable_fm,
	output	signed [11:0] left_out,
	output	signed [11:0] right_out,
	output	sample_out
);

wire signed [11:0] fm6_left, fm6_right;
wire fir6_sample;
wire signed [11:0] psg_fir6;

wire signed [11:0] fir4_left, fir4_right;

// Rebuilt the input reset in order to
// reduce its load. Makes synthesis easier
reg [1:0] rst_int_aux;
reg rst_int;

always @(posedge clk or posedge rst) 
	if( rst ) begin
		rst_int_aux	<= 2'b11;
		rst_int		<= 1'b1;
	end
	else begin		
		{ rst_int, rst_int_aux } <= { rst_int_aux, 1'b0 };
	end


// Change sampling frequency from 54kHz to 321kHz
// interpolating by 6. This is done using the multiplexed output
// as in the original chip

wire signed [8:0] fm_gated_left  = enable_fm ? left_in  : 9'd0;
wire signed [8:0] fm_gated_right = enable_fm ? right_in : 9'd0;


jt12_fir #(.output_width(12)) u_fir6 (
	.clk		( clk 			),
	.rst		( rst_int  		),
	.sample		( sample	 	),
	.left_in	( fm_gated_left	),
	.right_in	( fm_gated_right),
	.left_out	( fm6_left 		),
	.right_out	( fm6_right 	),
	.sample_out	( fir6_sample 	)
);

wire signed [11:0] psg_gated = {12{enable_psg}} & psg;

jt12_fir #(.output_width(12)) u_fir6_psg (
	.clk		( clk 			),
	.rst		( rst_int  		),
	.sample		( sample	 	),
	.left_in	( psg_gated[11:3]),
	.right_in	( 9'd0			),
	.left_out	( psg_fir6	 	)
);

// Interpolate by 4 to obtain sampling frequency of 1.28MHz
// With that oversampling ratio, a 2nd order sigma delta
// has 11.5bit resolution even with a 1-bit quantizer

wire signed [11:0] psg_att = psg_fir6>>>2;

reg signed [11:0] amp_left, amp_right;

jt12_interpol u_interpol(
	.clk		( clk 			),
	.rst		( rst_int  		),
	.sample_in	( fir6_sample 	),
	.left_in	( fm6_left		),
	.right_in	( fm6_right		),

	.left_other	( psg_att		),
	.right_other( psg_att		),

	.left_out	( fir4_left		),
	.right_out	( fir4_right	),
	.sample_out	( sample_out	)
);

assign left_out  = fir4_left>>>(7-volume);
assign right_out = fir4_right>>>(7-volume);

endmodule
