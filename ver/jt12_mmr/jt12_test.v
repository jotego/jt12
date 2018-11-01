`timescale 1ns / 1ps

module jt12_test;

reg	rst;
reg	clk;
reg flag_A, flag_B;

wire s1_enters, s2_enters, s3_enters, s4_enters;

`include "../common/dump.vh"

initial begin
	clk = 0;
    forever #10 clk=~clk;
end


initial begin
	rst = 0;
	flag_A = 0;
	flag_B = 0;
    #5 rst = 1;
    #20 rst = 0;
    //$finish;
end
/*
always @(posedge clk)
	if( rst ) begin

	end else begin
		//
	end
*/
// PCM
wire		[8:0]	pcm;
wire				pcm_en;
`ifdef TEST_SUPPORT		
// Test
wire			test_eg;
wire			test_op0;
`endif
// REG
wire	[2:0]	block_I;
wire	[1:0]	rl;
wire	[2:0]	fb_II;
wire	[2:0]	con;
wire	[10:0]	fnum_I;
wire	[2:0]	pms_I;
wire	[1:0]	ams_IV;
wire	[2:0]	dt1_II;
wire	[3:0]	mul_V;
wire	[6:0]	tl_IV;
wire	[1:0]	ks_II;
wire	[4:0]	ar_I;
wire			amsen_IV;
wire	[4:0]	d1r_I;
wire	[4:0]	d2r_I;
wire	[3:0]	sl_I;
wire	[3:0]	rr_I;
wire			ssg_en_I;
wire	[2:0]	ssg_eg_I;
wire			keyon_I;
//wire	[1:0]	cur_op;
wire			zero;
	
wire 	[2:0]	lfo_freq;
wire	[9:0]	value_A;
wire	[7:0]	value_B;
wire	[2:0]	alg;	

wire	cs_n, wr_n, prog_done;
wire	[7:0]	din;
wire	[1:0]	addr;
wire			busy;

wire	[3:0]	s_hot = { s4_enters, s2_enters, s3_enters, s1_enters };

jt12_testdata #(.rand_wait(`RANDWAIT)) u_testdata(
	.rst	( rst		),
	.clk	( clk		),
	.cs_n	( cs_n		),
	.wr_n	( wr_n		),
	.dout	( din		),
	.din	( { busy, 5'd0, flag_B, flag_A } ),
	.addr	( addr		),
	.prog_done(prog_done)
);

initial begin
	$display("DUMP START");
end

always @(posedge clk) if(clk_en) begin
	$display("%X,%X %X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X / %X,%X,%X,%X,%X,%X,%X", 
    	u_uut.u_reg.cur_op, u_uut.u_reg.cur_ch,

    	dt1_II, mul_V, tl_IV, ks_II, ar_I,
    	amsen_IV, d1r_I, d2r_I, sl_I, rr_I, ssg_en_I, ssg_eg_I, 

    	block_I, fnum_I,
    	fb_II, alg,
    	rl, ams_IV, pms_I );
end

always @(posedge clk) begin
	if( prog_done ) begin    	
    	#10000 
        $display("DUMP END");
        $finish;
    end
end

wire clk_en, load_A, load_B, lfo_en, enable_irq_A, enable_irq_B, clr_flag_A, clr_flag_B;
wire use_prevprev1, use_internal_x, use_internal_y, use_prev2, use_prev1;
wire fast_timers;
wire overflow_A = 1'b0;
wire pg_stop, eg_stop, ch6op;
		

jt12_mmr u_uut(
	.rst	( rst		),
	.clk	( clk		),				// PM
	.cen	( 1'b1		),
	.clk_en	( clk_en	),
	.din	( din		),
	.write	( ~wr_n		),
	.addr	( addr		),
	.busy	( busy		),

	// LFO
	.lfo_freq(lfo_freq),
	.lfo_en(lfo_en),
	// Timers
	.value_A(value_A),
	.value_B(value_B),
	.load_A(load_A),
	.load_B(load_B),
	.enable_irq_A(enable_irq_A),
	.enable_irq_B(enable_irq_B),
	.clr_flag_A(clr_flag_A),
	.clr_flag_B(clr_flag_B),
	.flag_A(flag_A),
	.fast_timers(fast_timers),
	.overflow_A( overflow_A ),
	// PCM
	.pcm(pcm),
	.pcm_en(pcm_en),

	`ifdef TEST_SUPPORT		
	// Test
	.test_eg(test_eg),
	.test_op0(test_op0),	
	`endif
	.eg_stop( eg_stop ),
	.pg_stop( pg_stop ),
    // Operator
	.use_prevprev1(use_prevprev1),
	.use_internal_x(use_internal_x),
	.use_internal_y(use_internal_y),	
	.use_prev2(use_prev2),
	.use_prev1(use_prev1),    
	// PG
	.fnum_I(fnum_I),
	.block_I( block_I ),	
	// REG
	.rl(rl),
	.fb_II(fb_II),
	.alg(alg),
	.pms_I(	pms_I),
	.ams_IV(ams_IV),
	.amsen_IV(amsen_IV),    
	.dt1_II(	dt1_II),
	.mul_V(	mul_V ),
	.tl_IV(	tl_IV ),

	.ar_I(	ar_I ),
	.d1r_I(	d1r_I ),
	.d2r_I(	d2r_I ),
	.rr_I(	rr_I ),
	.sl_I(	sl_I ),
	.ks_II(	ks_II ),
	// SSG operation
	.ssg_en_I(ssg_en_I),
	.ssg_eg_I(ssg_eg_I),
        
	.keyon_I(keyon_I),

//	output	[ 1:0]	cur_op,
	// Operator
	.zero(zero),
	.ch6op(ch6op),
	.s1_enters(s1_enters),
	.s2_enters(s2_enters),
	.s3_enters(s3_enters),
	.s4_enters(s4_enters)
);

endmodule
