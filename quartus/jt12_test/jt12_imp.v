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
	output			syn_left,
	output 			syn_right,	
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

jt12_top uut(
	.rst		( rst	),
	.cpu_clk	( cpu_clk),
	.cpu_din	( din	),
	.cpu_addr	( addr	),
	.cpu_cs_n	( cs_n	),
	.cpu_wr_n	( wr_n	),

	.cpu_limiter_en( limiter_en ),

	.cpu_dout	( dout		),
	.cpu_irq_n	( irq_n		),
	// Synthesizer clock domain
	.syn_clk	( syn_clk	),
	// FIR filters clock
	.fir_clk	( clk		),
	.fir_volume	( 3'd7		),
	// 1 bit output per channel at 1.3MHz
	.syn_left	( syn_left	),
	.syn_right	( syn_right	)
);

endmodule
