module jt12_imp(
	input			rst,
	input			clk,
	input			clk_en,
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

wire [7:0] dout;
assign busy = dout[7];
assign flag_B = dout[1];
assign flag_A = dout[0];

jt12 u_fm(
	.rst	( rst	),
	.clk	( clk	),
    .clk_en	( clk_en ),
	.din	( din	),
	.addr	( addr	),
	.cs_n	( cs_n	),
	.wr_n	( wr_n	),

	.limiter_en( limiter_en ),

	.dout	( dout	),
	/*
	.snd_right	( right	),
	.snd_left	( left	),
	.sample	( sample	),
*/
	// muxed output
	.mux_left	( mux_left	),
	.mux_right	( mux_right ),
	.mux_sample	( mux_sample),

    .irq_n	( irq_n	)
);

endmodule
