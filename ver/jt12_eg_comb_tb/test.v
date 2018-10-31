

module test(
	input				keyon_now,
	input				keyoff_now,
	input		[2:0]	state_in,
	input		[9:0]	eg_in,
	// envelope configuration	
	input		[4:0]	arate, // attack  rate
	input		[4:0]	rate1, // decay   rate
	input		[4:0]	rate2, // sustain rate
	input		[3:0]	rrate,
	input		[3:0]	sl,   // sustain level
	// SSG operation
	input				ssg_en,
	input		[2:0]	ssg_eg,
	// SSG output inversion
	input				ssg_inv_in,
	output reg			ssg_inv_out,
	// SSG output hold
	input				ssg_lock_in,
	output reg			ssg_lock_out,

	output reg	[2:0]	state_next,
	output reg			pg_rst,
	///////////////////////////////////
	// II
	input [ 4:0] 	keycode,
	input [14:0] 	eg_cnt,
	input        	cnt_in,
	input [ 1:0] 	ks,
	output       	cnt_lsb,
	///////////////////////////////////
	// III
	output reg  [9:0] pure_eg_out,
	///////////////////////////////////
	// IV
	input [ 6:0] 	lfo_mod,
	input        	amsen,
	input [ 1:0] 	ams,
	input [ 6:0] 	tl,
	output reg	[9:0] eg_out
);

wire ssg_inv_out, ssg_lock_out;
wire [4:0]	base_rate;
wire 		attack = state_next[0];
wire		step;
wire [5:0] step_rate_out;

jt12_eg_comb uut(
	.keyon_now		( keyon_now		),
	.keyoff_now		( keyoff_now	),
	.state_in		( state_in		),
	.eg_in			( eg_in			),
	// envelope configuration	
	.arate			( arate			), // attack  rate
	.rate1			( rate1			), // decay   rate
	.rate2			( rate2			), // sustain rate
	.rrate			( rrate			),
	.sl				( sl			),   // sustain level
	// SSG operation
	.ssg_en			( ssg_en		),
	.ssg_eg			( ssg_eg		),
	// SSG output inversion
	.ssg_inv_in		( ssg_inv_in	),
	.ssg_inv_out	( ssg_inv_out	),

	.base_rate		( base_rate		),
	.state_next		( state_next	),
	.pg_rst			( pg_rst		),
	///////////////////////////////////
	// II
	.step_attack	( attack		),
	.step_rate_in	( base_rate		),
	.keycode		( keycode		),
	.eg_cnt			( eg_cnt		),
	.cnt_in			( cnt_in		),
	.ks				( ks			),
	.cnt_lsb		( cnt_lsb		),
	.step			( step			),
	.step_rate_out	( step_rate_out	),
	///////////////////////////////////
	// III
	.pure_attack	( attack		),
	.pure_step		( step			) ,
	.pure_rate		(step_rate_out[5:1]),
	.pure_ssg_en	( ssg_en		), // from I
	.pure_eg_in		( eg_in			),
	.pure_eg_out	( pure_eg_out	),
	///////////////////////////////////
	// IV
	.lfo_mod		( lfo_mod		),
	.amsen			( amsen			),
	.ams			( ams			),
	.tl				( tl			),
	.final_ssg_inv	( ssg_inv_out	), // from I
	.final_eg_in	( pure_eg_out	),
	.final_eg_out	( eg_out		)
);

endmodule // test