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
reg vclk, syn_clk;

reg rst0;

initial begin
	rst0=0;
    #10 rst0=1;
    #10 rst0=0;
end

initial begin
	syn_clk=0;
	forever #750 syn_clk = ~syn_clk;
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

integer limit_time_cnt;

initial begin
	rst = 0;
    limit_time_cnt=0;
    #500 rst = 1;
    #600 rst = 0;
	// reset again, when all the pipeline is clear
	#(2500*1000) rst=1;
	#1000 rst=0;
end

`ifdef LIMITTIME
initial begin
    for( limit_time_cnt=`LIMITTIME; limit_time_cnt>0; limit_time_cnt=limit_time_cnt-1 )
		#(1000*1000);
	$finish;
end
`endif


wire	cs_n, wr_n, prog_done;
wire	[ 7:0]	din, dout;
wire signed	[11:0]	right, left;
wire	[ 1:0]	addr;

jt12_testdata #(.rand_wait(`RANDWAIT)) u_testdata(
	.rst	( rst	),
	.clk	( vclk	),
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
/*
jt12 uut(
	.rst		( rst	),
	.cpu_clk	( vclk	),
	.syn_clk	( syn_clk),
	.cpu_din	( din	),
	.cpu_addr	( addr	),
	.cpu_cs_n	( cs_n	),
	.cpu_wr_n	( wr_n	),

	.cpu_limiter_en( 1'b1 ),

	.cpu_dout	( dout	),
	.syn_snd_right	( right	),
	.syn_snd_left	( left	),
	.syn_snd_sample	( sample	),

	// muxed output
	.syn_mux_left	( mux_left	),
	.syn_mux_right	( mux_right ),
	.syn_mux_sample	( mux_sample),

    .cpu_irq_n	( irq_n	)
);
*/

wire syn_left, syn_right;

jt12_top uut(
	.rst		( rst	),
	.cpu_clk	( vclk	),
	.cpu_din	( din	),
	.cpu_addr	( addr	),
	.cpu_cs_n	( cs_n	),
	.cpu_wr_n	( wr_n	),

	.cpu_limiter_en( 1'b1 ),

	.cpu_dout	( dout		),
	.cpu_irq_n	( irq_n		),
	// Synthesizer clock domain
	.syn_clk	( syn_clk	),
	// FIR filters clock
	.fir_clk	( mclk		),
	.fir_volume	( 3'd7		),
	// 1 bit output per channel at 1.3MHz
	.syn_left	( syn_left	),
	.syn_right	( syn_right	)
);


`ifdef POSTPROC

wire [4:0] syn_sinc1;
wire [8:0] syn_sinc2;
wire [13:0] syn_sinc3;

sincf #(.win(1), .wout(5)) sinc1(
	.clk ( syn_clk ),
	.din ( syn_left ),
	.dout( syn_sinc1 )
);

sincf #(.win(5), .wout(9)) sinc2(
	.clk ( syn_clk ),
	.din ( syn_sinc1 ),
	.dout( syn_sinc2 )
);

sincf #(.win(9), .wout(14)) sinc3(
	.clk ( syn_clk ),
	.din ( syn_sinc2 ),
	.dout( syn_sinc3 )
);


/*
real filter_left;
// real tau=5e-6;

always @(posedge mclk)
if ( rst )
	filter_left <= 0;
else begin
	if( syn_left )
    	filter_left <= filter_left + 5.26e-9/5e-6 * (1.0-filter_left);
	else
	    filter_left <= filter_left - 5.26e-9/5e-6 * filter_left;
end

real speaker_left;

reg audio_clk;

initial begin
	audio_clk = 0;
    forever #22700 audio_clk = ~audio_clk;
end

always @(posedge audio_clk)
	speaker_left <= ((2*(filter_left-0.5))+speaker_left)/2;
*/
`endif

`ifdef DUMPSOUND
initial $display("DUMP START");
`endif

endmodule
