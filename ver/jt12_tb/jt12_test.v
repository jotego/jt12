`timescale 1ns / 1ps

module jt12_test;

reg	rst;

`include "../common/dump.vh"

/*
reg	clk;
initial begin
	clk = 0;
    forever #62.5 clk=~clk;
end
*/

reg mclk; // 54MHz clock

initial begin
	mclk = 0;
    forever #9.26 mclk=~mclk;
end

reg [2:0] clkcnt;
reg vclk;

reg rst0;

initial begin
	rst0=0;
    #10 rst0=1;
    #10 rst0=0;
end

always @(posedge mclk or posedge rst0)
	if( rst0 ) begin
    	clkcnt <= 3'd0;
    end
    else begin
    	if ( clkcnt== 3'b110 ) begin
        	clkcnt <= 3'd0;
        end
        else clkcnt <= clkcnt+1'b1;
        vclk <= clkcnt <= 3'd3;
    end

wire clk = vclk;

reg clk_en, clk_en2;

always @(negedge mclk or posedge rst0)
	if( rst0 )
		{ clk_en, clk_en2 } <= 2'b0;
	else begin
		clk_en2 <= vclk;
		clk_en <= !clk_en2 && vclk;
	end

integer limit_time_cnt;

initial begin
	rst = 0;
    limit_time_cnt=0;
    #500 rst = 1;
    #600 rst = 0;
	`ifdef LIMITTIME
    for( limit_time_cnt=`LIMITTIME; limit_time_cnt>0; limit_time_cnt=limit_time_cnt-1 )
		#(1000*1000);
	$finish;
    `endif
end


wire	cs_n, wr_n, prog_done;
wire	[ 7:0]	din, dout;
wire signed	[11:0]	right, left;
wire	[ 1:0]	addr;

jt12_testdata #(.rand_wait(`RANDWAIT)) u_testdata(
	.rst	( rst	),
	.clk	( mclk	),
	.clk_en ( clk_en),
	.cs_n	( cs_n	),
	.wr_n	( wr_n	),
	.dout	( din	),
	.din	( dout	),
	.addr	( addr	),
	.prog_done(prog_done)
);

always @(posedge clk)
	if( prog_done ) begin
    	#(2000*1000);
        `ifdef DUMPSOUND
        $display("DUMP END");
        `endif
        $finish;
     end

wire	sample, mux_sample;
wire signed [8:0] mux_left, mux_right;

jt12 uut(
	.rst	( rst	),
	.clk	( mclk	),
    .clk_en	( clk_en ),
	.din	( din	),
	.addr	( addr	),
	.cs_n	( cs_n	),
	.wr_n	( wr_n	),

	.limiter_en( 1'b1 ),

	.dout	( dout	),
	.snd_right	( right	),
	.snd_left	( left	),
	.sample	( sample	),

	// muxed output
	.mux_left	( mux_left	),
	.mux_right	( mux_right ),
	.mux_sample	( mux_sample),

    .irq_n	( irq_n	)
);

`ifdef POSTPROC

wire [11:0] mixed_left;

jt12_mixer u_mixer(
	.clk		( mclk 			),
	.rst		( rst  			),
	.sample		( mux_sample 	),
	.left_in	( mux_left 		),
	.right_in	( mux_right 	),
	.psg		( 5'd10			),
	.enable_psg	( 1'b1			),
	.enable_fm	( 1'b1			),
	.volume		( 3'd4			),
	.left_out	( mixed_left	)
);

wire dacleft;
reg dacrst;

initial begin
	dacrst=1;
    #80000 dacrst=0;
end

wire [15:0] dacin_left = { ~mixed_left, mixed_left[14:0]};

hybrid_pwm_sd dac(
	.clk	( mclk		),
    .n_reset( ~dacrst		),
    .din	( dacin_left	),
    .dout	( dacleft	)
);

real filter_left;
// real tau=5e-6;

always @(posedge mclk)
if ( dacrst )
	filter_left <= 0;
else begin
	if( dacleft )
    	filter_left <= filter_left + 9.26e-9/5e-6 * (1.0-filter_left);
	else
	    filter_left <= filter_left - 9.26e-9/5e-6 * filter_left;
end

real speaker_left;

reg audio_clk;

initial begin
	audio_clk = 0;
    forever #22700 audio_clk = ~audio_clk;
end

always @(posedge audio_clk)
	speaker_left <= filter_left;
`endif

`ifdef DUMPSOUND
initial $display("DUMP START");
`endif

endmodule
