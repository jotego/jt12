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
	output	signed [15:0] left_out,
	output	signed [15:0] right_out
);

wire signed [19:0] fir6_left, fir6_right;
wire fir6_sample;
wire signed [19:0] psg_fir6;

wire signed [19:0] fir4_left, fir4_right;

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

jt12_fir u_fir6 (
	.clk		( clk 			),
	.rst		( rst_int  		),
	.sample		( sample	 	),
	.left_in	( left_in 		),
	.right_in	( right_in	 	),
	.left_out	( fir6_left 	),
	.right_out	( fir6_right 	),
	.sample_out	( fir6_sample 	)
);

wire signed [11:0] psg_gated = {12{enable_psg}} & psg;

jt12_fir u_fir6_psg (
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

wire signed	fir4_sample;
wire signed [8:0] psg_att = psg_fir6>>>2;

wire signed [8:0] fm_gated_left  = {9{enable_fm}} & fir6_left[19:11];
wire signed [8:0] fm_gated_right = {9{enable_fm}} & fir6_right[19:11];

reg signed [15:0] amp_left, amp_right;
wire signed [15:0] amp5_left, amp5_right, amp4_left, amp4_right,
	amp3_left, amp3_right, amp2_left, amp2_right,
	amp1_left, amp1_right;

jt12_interpol u_interpol(
	.clk		( clk 			),
	.rst		( rst_int  		),
	.sample_in	( fir6_sample 	),
	.left_in	( fm_gated_left ),
	.right_in	( fm_gated_right),

	.left_other	( psg_att		),
	.right_other( psg_att		),

	.left_out	( fir4_left		),
	.right_out	( fir4_right	),
	.sample_out	( fir4_sample	)
);

jt12_limitamp #( .width(16), .shift(5) ) amp5 (
	.left_in	( fir4_left[19:4]),
	.right_in	( fir4_right[19:4]),
	.left_out	( amp5_left	),
	.right_out	( amp5_right)
);

jt12_limitamp #( .width(16), .shift(4) ) amp4 (
	.left_in	( fir4_left[19:4]),
	.right_in	( fir4_right[19:4]),
	.left_out	( amp4_left	),
	.right_out	( amp4_right)
);

jt12_limitamp #( .width(16), .shift(3) ) amp3 (
	.left_in	( fir4_left[19:4]),
	.right_in	( fir4_right[19:4]),
	.left_out	( amp3_left	),
	.right_out	( amp3_right)
);

jt12_limitamp #( .width(16), .shift(2) ) amp2 (
	.left_in	( fir4_left[19:4]),
	.right_in	( fir4_right[19:4]),
	.left_out	( amp2_left	),
	.right_out	( amp2_right)
);

jt12_limitamp #( .width(16), .shift(1) ) amp1 (
	.left_in	( fir4_left[19:4]),
	.right_in	( fir4_right[19:4]),
	.left_out	( amp1_left	),
	.right_out	( amp1_right)
);

always @(posedge clk) begin
	case(volume)
		3'd7: {amp_left, amp_right } <= { amp5_left, amp5_right };
		3'd6: {amp_left, amp_right } <= { amp4_left, amp4_right };
		3'd5: {amp_left, amp_right } <= { amp3_left, amp3_right };
		3'd4: {amp_left, amp_right } <= { amp2_left, amp2_right };
		3'd3: {amp_left, amp_right } <= { amp1_left, amp1_right };
		3'd2: {amp_left, amp_right} <= { fir4_left, fir4_right };
		3'd1: {amp_left, amp_right} <= { fir4_left>>>1, fir4_right>>>1 };
		3'd0: {amp_left, amp_right} <= { fir4_left>>>2, fir4_right>>>2 };
	endcase
end

assign left_out  = amp_left;
assign right_out = amp_right;

endmodule
