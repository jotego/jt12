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
	Date: 29-10-2018

	*/

module jt12_eg2 (
	`ifdef TEST_SUPPORT
	input				test_eg,
	`endif
	input			 	rst,
	input			 	clk,
	input				clk_en,
	input				zero,
	input				eg_stop,
	// envelope configuration
	input		[4:0]	keycode_III,
	input		[4:0]	arate_II, // attack  rate
	input		[4:0]	rate1_II, // decay   rate
	input		[4:0]	rate2_II, // sustain rate
	input		[3:0]	rrate_II, // release rate
	input		[3:0]	d1l_I,   // sustain level
	input		[1:0]	ks_III,	   // key scale
	// SSG operation
	input				ssg_en_II,
	input		[2:0]	ssg_eg_II,
	// envelope operation
	input				keyon_I,
	// envelope number
	input		[6:0]	lfo_mod,
	input		[6:0]	tl_VII,
	input		[1:0]	ams_VII,
	input				amsen_VII,

	output	reg	[9:0]	eg_IX,
	output	reg			pg_rst_III
);

wire [14:0] eg_cnt;

jt12_eg_cnt u_egcnt(
	.rst	( rst 	),
	.clk	( clk 	),
	.clk_en	( clk_en),
	.zero	( zero	),
	.eg_cnt	( eg_cnt)
);

// I stage
wire keyon_last_I;
wire keyon_now_I  = !keyon_last_I && keyon_I;
wire keyoff_now_I = keyon_last_I && !keyon_I;


wire cnt_out, cnt_in, step_II;
wire [5:0] rate_II;

// II stage
jt12_eg_step u_step(
	input attack,
	input [ 4:0] base_rate,
	.keycode	( keycode_II),
	.eg_cnt		( eg_cnt 	),
	.cnt_in		( cnt_in	),
	.ks			( ks_II		),
	.cnt_lsb	( cnt_out	),
	.step		( step_II	),
	.rate		( rate_II	),
);

// III stage
reg [5:1] rate_III;
reg step_III;
always @(posedge clk) 
	if(clk_en) begin
		rate_III <= rate_II[5:1];
		step_III <= step_II;
	end


wire [9:0] eg_IIIin, eg_IIIout;
jt12_eg_pure u_pure(
	input attack,
	.rate	( rate_III	),
	.eg_in	( eg_IIIin	),
	.eg_pure( eg_IIIout	)
);

// IV stage
reg [9:0] eg_IV;
always @(posedge clk) 
	if(clk_en) eg_IV <= eg_IIIout;

jt12_eg_final u_final(
	.lfo_mod( lfo_mod	),
	.amsen	( amsen_IV	),
	.ams	( ams_IV	),
	.tl		( tl_IV		),
	.eg_pure( eg_IV		),
	output reg	[9:0] eg_limited
);

jt12_sh #( .width(1), .stages(24) ) u_cntsh(
	.clk	( clk		),
	.clk_en	( clk_en	),
	.din	( cnt_out	),
	.drop	( cnt_in	)
);

jt12_sh_rst #( .width(10), .stages(24), .rstval(1'b1) ) u_egsh(
	.clk	( clk		),
	.clk_en	( clk_en	),
	.rst	( rst		),
	.din	( eg_IIIout	),
	.drop	( eg_IIIin	)
);

jt12_sh_rst #( .width(1), .stages(24), .rstval(1'b0) ) u_konsh(
	.clk	( clk		),
	.clk_en	( clk_en	),
	.rst	( rst		),	
	.din	( keyon_I	),
	.drop	( keyon_last_I	)
);


endmodule // jt12_eg