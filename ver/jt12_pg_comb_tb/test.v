
module test(
	input		[ 2:0]	block,
	input		[10:0]  fnum,
	// Phase Modulation
	input		[ 4:0]  lfo_mod,
	input		[ 2:0]  pms,
	// Detune
	input		[ 2:0]	detune,

	output 		[ 4:0]	keycode,
	// Phase add
	input		[ 3:0]	mul,
	input		[19:0]	phase_in,
	input				pg_rst,

	output		[19:0]	phase_out,
	output		[ 9:0]	phase_op,

	output		[16:0]  phinc
);

wire signed [ 5:0]	dt;
// wire		[16:0]  phinc;

jt12_pg_comb u_uut(
	.block		( block		),
	.fnum		( fnum		),
	// Phase Modulation
	.lfo_mod	( lfo_mod	),
	.pms		( pms		),
	// Detune
	.detune		( detune	),

	.keycode	( keycode	),
	.detune_out	( dt		),
	// Phase increment	
	.phinc_out	( phinc		),
	// Phase add
	.mul		( mul		),
	.phase_in	( phase_in	),
	.pg_rst		( pg_rst	),
	.detune_in	( dt		),
	.phinc_in	( phinc		),

	.phase_out	( phase_out	),
	.phase_op	( phase_op	)
);

endmodule;