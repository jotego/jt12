module jt12_imp(
	input			rst,
	input			clk,
	input	[7:0]	din,
	input	[1:0]	addr,
	input			cs_n,
	input			wr_n,
	input			limiter_en,

	output			busy,
	output			flag_B,
	output			flag_A,
	// combined output
	/*
	output	[11:0]	snd_right,
	output	[11:0]	snd_left,
	output			sample,
	*/
	// multiplexed output
	output signed	[8:0]	mux_left,
	output signed	[8:0]	mux_right,	
	output			mux_sample,
		
	output			irq_n
);

wire syn_clk, cpu_clk,locked;

syn_clk_gen u_pll(
	.areset(rst),
	.inclk0(clk),
	.c0(syn_clk),
	.c1(cpu_clk),
	.locked(locked));

wire [7:0] dout;
assign busy = dout[7];
assign flag_B = dout[1];
assign flag_A = dout[0];

jt12 u_fm(
	.rst		( rst	),
	.cpu_clk	( cpu_clk),
	.syn_clk	( syn_clk),
	.cpu_din	( din	),
	.cpu_addr	( addr	),
	.cpu_cs_n	( cs_n	),
	.cpu_wr_n	( wr_n	),

	.cpu_limiter_en( limiter_en ),

	.cpu_dout	( dout	),
	/*
	.snd_right	( right	),
	.snd_left	( left	),
	.sample	( sample	),
*/
	// muxed output
	.syn_mux_left	( mux_left	),
	.syn_mux_right	( mux_right ),
	.syn_mux_sample	( mux_sample),

    .cpu_irq_n	( irq_n	)
);

endmodule
