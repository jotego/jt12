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


module jt12_reg(
	input				rst,
	input				clk,
	input	[7:0]		din,
	
	input	[2:0]		ch,
	input	[1:0]		op,
	
	input				csm,
	input				flag_A,
	input				overflow_A,

	input				up_keyon,	
	input				up_alg,	
	input				up_block,
	input				up_fnumlo,
	input				up_pms,
	input				up_dt1,
	input				up_tl,
	input				up_ks_ar,
	input				up_amen_d1r,
    input				up_d2r,
        
	input				up_d1l,
	input				up_ssgeg,
   	input				up_kon,

	output				busy,
    
	// CH3 Effect-mode operation
	input				effect,
	input	[10:0]		fnum_ch3op2,
	input	[10:0]		fnum_ch3op3, 
	input	[10:0]		fnum_ch3op1,
	input	[ 2:0]		block_ch3op2,
	input	[ 2:0]		block_ch3op3,
	input	[ 2:0]		block_ch3op1,
    // Pipeline order
	output	reg			zero,
	output 				s1_enters,
	output 				s2_enters,
	output 				s3_enters,
	output 				s4_enters,
    
    // Operator
	output 				use_prevprev1,
	output 				use_internal_x,
	output 				use_internal_y,	
	output 				use_prev2,
	output 				use_prev1,
	
	// PG
	output		[10:0]	fnum_I,
	output		[ 2:0]	block_I,
	// channel configuration
	output		[1:0]	rl,
	output reg	[2:0]	fb_II,
	output		[2:0]	alg,
	// Operator multiplying
	output		[ 3:0]	mul_V,
	// Operator detuning
	output		[ 2:0]	dt1_II,
	
	// EG
	output		[4:0]	ar_II,	// attack  rate
	output		[4:0]	d1r_II, // decay   rate
	output		[4:0]	d2r_II, // sustain rate
	output		[3:0]	rr_II,	// release rate
	output		[3:0]	d1l,   // sustain level
	output		[1:0]	ks_III,	   // key scale
	output				ssg_en_II,
	output		[2:0]	ssg_eg_II,
	output		[6:0]	tl_VII,
	output		[2:0]	pms,
	output		[1:0]	ams_VII,
	output				amsen_VII,

	// envelope operation
	output				keyon_II,
	output				keyoff_II
);


reg	 [4:0] opch_I;
wire [4:0] opch_II, opch_III, opch_IV, opch_V, opch_VI, opch_VII;
reg	[4:0] next, cnt, cur;
wire [2:0]	fb_I;

always @(posedge clk) fb_II <= fb_I;

always @(*) begin
	case( op )
		2'd0: opch_I <= ch;
		2'd1: opch_I <= ch+4'd6;
		2'd2: opch_I <= ch+4'd12;
		2'd3: opch_I <= ch+5'd18;
	endcase
end

// FNUM and BLOCK
wire	[10:0]	fnum_I_raw;
wire	[ 2:0]	block_I_raw;
wire	effect_on_s1 = effect && (cur == 5'd02 );
wire	effect_on_s3 = effect && (cur == 5'd08 );
wire	effect_on_s2 = effect && (cur == 5'd14 );
wire	noeffect     = ~|{effect_on_s1, effect_on_s3, effect_on_s2};
assign fnum_I = ( {11{effect_on_s1}} & fnum_ch3op1 ) |
				( {11{effect_on_s2}} & fnum_ch3op2 ) |
				( {11{effect_on_s3}} & fnum_ch3op3 ) |
				( {11{noeffect}}     & fnum_I_raw  );

assign block_I =( {3{effect_on_s1}} & block_ch3op1 ) |
				( {3{effect_on_s2}} & block_ch3op2 ) |
				( {3{effect_on_s3}} & block_ch3op3 ) |
				( {3{noeffect}}     & block_I_raw  );


jt12_mod24 u_opch_II ( .base(opch_I), .extra(3'd1), .mod(opch_II)  );
jt12_mod24 u_opch_III( .base(opch_I), .extra(3'd2), .mod(opch_III) );
jt12_mod24 u_opch_IV ( .base(opch_I), .extra(3'd3), .mod(opch_IV)  );
jt12_mod24 u_opch_V  ( .base(opch_I), .extra(3'd4), .mod(opch_V)   );
jt12_mod24 u_opch_VI ( .base(opch_I), .extra(3'd5), .mod(opch_VI)  );
jt12_mod24 u_opch_VII( .base(opch_I), .extra(3'd6), .mod(opch_VII) );

wire update_op_I  = cur == opch_I;
wire update_op_II = cur == opch_II;
wire update_op_III= cur == opch_III;
// wire update_op_IV = cur == opch_IV;
wire update_op_V  = cur == opch_V;
// wire update_op_VI = cur == opch_VI;
wire update_op_VII= cur == opch_VII;

// key on/off
wire	[3:0]	keyon_op = din[7:4];
wire	[2:0]	keyon_ch = din[2:0];
// channel data
wire	[1:0]	rl_in	= din[7:6];
wire	[2:0]	fb_in	= din[5:3];
wire	[2:0]	alg_in	= din[2:0];
wire	[2:0]	pms_in	= din[2:0];
wire	[1:0]	ams_in	= din[5:4];
wire	[2:0]	block_in= din[5:3];
wire	[2:0]	fnhi_in	= din[2:0];
wire	[7:0]	fnlo_in	= din;
// operator data
wire	[2:0]	dt1_in	= din[6:4];
wire	[3:0]	mul_in	= din[3:0];
wire	[6:0]	tl_in	= din[6:0];
wire	[1:0]	ks_in	= din[7:6];
wire	[4:0]	ar_in	= din[4:0];
wire			amen_in	= din[7];
wire	[4:0]	d1r_in	= din[4:0];
wire	[4:0]	d2r_in	= din[4:0];
wire	[3:0]	d1l_in	= din[7:4];
wire	[3:0]	rr_in	= din[3:0];
wire	[3:0]	ssg_in	= din[3:0];

wire	[3:0]	ssg;

reg			last;

wire	update_ch_I  = cur == ch;
//wire	update_ch_II = cur == ch+1;
/*
wire	update_ch_III= ch == ch_III;
wire	update_ch_IV = ch == ch_IV;
wire	update_ch_V  = ch == ch_V;
wire	update_ch_VI = ch == ch_VI;
*/

wire up_alg_ch	= up_alg	& update_ch_I;
// wire up_fb_ch	= up_alg	& update_ch_II;
wire up_block_ch= up_block	& update_ch_I;
wire up_fnumlo_ch=up_fnumlo & update_ch_I;
wire up_pms_ch	= up_pms	& update_ch_I;

// DT1 & MUL
wire up_dt1_op	= up_dt1	& update_op_II;
wire up_mul_op	= up_dt1	& update_op_V;
// TL
wire up_tl_op	= up_tl		& update_op_VII;
// KS & AR
wire up_ks_op	= up_ks_ar	& update_op_III;
wire up_ar_op	= up_ks_ar	& update_op_II;
// AM ON, D1R
wire up_amen_op	= up_amen_d1r	& update_op_VII;
wire up_d1r_op	= up_amen_d1r	& update_op_II;
// Sustain Rate (D2R)
wire up_d2r_op	= up_d2r	& update_op_II;
// D1L & RR
wire up_d1l_op	= up_d1l	& update_op_I;
wire up_rr_op	= up_d1l	& update_op_II;
// SSG
//wire up_ssgen_op = up_ssgeg	& update_op_I;
wire up_ssg_op	= up_ssgeg	& update_op_II;

wire up = 	up_alg 	| up_block 	| up_fnumlo | up_pms |
			up_dt1 	| up_tl 	| up_ks_ar	| up_amen_d1r | 
            up_d2r	| up_d1l 	| up_ssgeg;


always @(*) begin
	next <= cur==5'd23 ? 5'd0 : cur +1'b1;
end

reg		busy_op; 
wire	busy_kon;

assign	busy = busy_op | busy_kon;


always @(posedge clk) begin : up_counter
	if( rst ) begin
		cnt		<= 5'h0;
		cur		<= 5'h0;
		last	<= 1'b0;
		zero	<= 1'b0;
		busy_op	<= 1'b0;
	end
	else begin
		cur		<= next;
		zero 	<= next == 5'd0;
		last	<= up;
		if( up && !last ) begin
			cnt		<= cur;
			busy_op	<= 1'b1;
		end
		else if( cnt == cur ) busy_op <= 1'b0;
	end
end

jt12_kon u_kon(
	.rst		( rst		),
	.clk		( clk		),
	.keyon_op	( keyon_op	),
	.keyon_ch	( keyon_ch	),
	.next_slot	( next		),
	.up_keyon	( up_keyon	),
	.csm		( csm		),
	.flag_A		( flag_A	),
	.overflow_A	( overflow_A),
	
	.keyon_II	( keyon_II	),
	.keyoff_II	( keyoff_II	),
	.busy		( busy_kon	)
);


jt12_opsync u_opsync(
	.rst	( rst		),
	.clk	( clk		),
    .next	( next 		),
	.s1_enters	( s1_enters ),
	.s2_enters	( s2_enters ),
	.s3_enters	( s3_enters ),
	.s4_enters	( s4_enters )
);	

jt12_fm u_fm(
	.alg_I		( alg		),
	.s1_enters	( s1_enters ),
	.s3_enters	( s3_enters ),
	.s2_enters	( s2_enters ),
	.s4_enters	( s4_enters ),
	
	.use_prevprev1 ( use_prevprev1  ),
	.use_internal_x( use_internal_x ),
	.use_internal_y( use_internal_y ),	
	.use_prev2	 ( use_prev2	  ),
	.use_prev1	 ( use_prev1	  )
);

// memory for OP registers
parameter regop_width=44;

wire [regop_width-1:0] regop_in, regop_out;

assign regop_in = {
	up_dt1_op	? dt1_in : dt1_II,	// 3
    up_mul_op	? mul_in : mul_V,	// 4 - 7
    up_tl_op	? tl_in	 : tl_VII,	// 7 - 14
    up_ks_op	? ks_in	 : ks_III,	// 2 - 16
    up_ar_op	? ar_in	 : ar_II,	// 5 - 21
    up_amen_op	? amen_in: amsen_VII,// 1 - 22
    up_d1r_op	? d1r_in : d1r_II,	// 5 - 25
    up_d2r_op	? d2r_in : d2r_II,	// 5 - 30
    up_d1l_op	? d1l_in : d1l,		// 4 - 34
    up_rr_op	? rr_in	 : rr_II,	// 4 - 38
    up_ssg_op	? ssg_in[3]   : ssg_en_II,	// 1 - 39
    up_ssg_op	? ssg_in[2:0] : ssg_eg_II	// 3 - 42
};

assign { 	dt1_II, mul_V,	tl_VII, ks_III, 
			ar_II,	amsen_VII, d1r_II, d2r_II, d1l, rr_II,
            ssg_en_II,	ssg_eg_II 				} = regop_out;

jt12_sh #(.width(regop_width),.stages(24)) u_regop(
	.clk	( clk		),
	.din	( regop_in	),
	.drop	( regop_out	)
);

// memory for CH registers
parameter regch_width=27;
wire [regch_width-1:0] regch_out;
wire [regch_width-1:0] regch_in = { 
	up_block_ch	? { block_in, fnhi_in } : { block_I_raw, fnum_I_raw[10:8] }, // 3+3
	up_fnumlo_ch?   fnlo_in : fnum_I_raw[7:0], // 8	
	up_alg_ch	? { fb_in, alg_in } : { fb_I, alg },//3+3
	//up_alg_ch	? alg_in : alg,//3+3
	//up_fb_ch	? fb_in  : fb_II,//3+3
	up_pms_ch	? { rl_in, ams_in, pms_in } : { rl, ams_VII, pms }//2+2+3
}; 
		
assign { block_I_raw, fnum_I_raw, fb_I, alg, rl, ams_VII, pms } = regch_out;

jt12_sh #(.width(regch_width),.stages(6)) u_regch(
	.clk	( clk		),
	.din	( regch_in	),
	.drop	( regch_out	)
);

endmodule
