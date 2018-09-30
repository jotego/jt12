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

	Based on information provided by
		Sauraen VHDL version of OPN/OPN2, which is based on die shots.
		Nemesis reports, based on measurements
		Comparisons with real hardware lent by Mikes (Va de retro)

	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: 14th March, 2017
	
	Use tab = 4 spaces
	
	fir_clk	=> 54MHz
	cpu_clk	=> fir_clk/7 = 7.7MHz
	syn_clk => cpu_clk/6 = 1.3MHz
	
	syn_mux_sample => syn_clk/24 = 53.6 kHz

*/

module jt12_top(
	input			rst,
	// CPU interface
	input			cpu_clk,
	input	[7:0]	cpu_din,
	input	[1:0]	cpu_addr,
	input			cpu_cs_n,
	input			cpu_wr_n,
	input			cpu_limiter_en,

	output	[7:0]	cpu_dout,
	output			cpu_irq_n,
	// Synthesizer clock domain
	input			syn_clk,
	// FIR filters clock
	input			fir_clk,
	input	[2:0]	fir_volume,
	input			enable_fm,
	input			enable_psg,
	// 1 bit output per channel at 1.3MHz
	output			syn_left,
	output			syn_right
);

wire signed [8:0] syn_mux_left, syn_mux_right;
wire syn_mux_sample;

jt12 u_jt12(
	.rst		( rst		),
	.cpu_clk	( cpu_clk	),
	.syn_clk	( syn_clk	),
	.cpu_din	( cpu_din	),
	.cpu_addr	( cpu_addr	),
	.cpu_cs_n	( cpu_cs_n	),
	.cpu_wr_n	( cpu_wr_n	),

	.cpu_limiter_en( cpu_limiter_en ),

	.cpu_dout	( cpu_dout	),
	// muxed output
	.syn_mux_left	( syn_mux_left	),
	.syn_mux_right	( syn_mux_right ),
	.syn_mux_sample	( syn_mux_sample),

    .cpu_irq_n	( cpu_irq_n	)
);

wire signed [11:0] fir_left, fir_right;
wire fir_sample_out;

jt12_mixer u_mixer(
	.rst		( rst  			),
	.clk		( fir_clk		),
	.sample		( syn_mux_sample 	),
	.left_in	( syn_mux_left 		),
	.right_in	( syn_mux_right 	),
	.psg		( 12'd0		),
	.enable_psg	( enable_psg),
	.enable_fm	( enable_fm	),
	.volume		( fir_volume),
	.left_out	( fir_left	),
	.right_out	( fir_right	),
	.sample_out	( fir_sample_out	)
);
/*
jt12_sh #(.width(1), .stages(2)) u_sample_sync(
	.clk	( syn_clk	),
	.din	( fir_sample_out ),
	.drop	( syn_sample_out )
);
*/
jt12_dac u_dac_left(
	.rst		( rst  			),
	.clk		( syn_clk		),
	.din		( fir_left		),
	.dout		( syn_left		)
);

jt12_dac2 u_dac_right(
	.rst		( rst  			),
	.clk		( syn_clk		),
	.din		( fir_right		),
	.dout		( syn_right		)
);

endmodule
