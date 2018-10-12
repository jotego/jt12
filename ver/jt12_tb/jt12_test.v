`timescale 1ns / 1ps

module jt12_test;

reg	rst;

`include "../common/dump.vh"


reg clk; // 4MHz clock

initial begin
	clk = 0;
    forever #125 clk=~clk;
end

reg [1:0] clkcnt;
reg clk_en;

reg rst0;

initial begin
	rst0=0;
    #10 rst0=1;
    #10 rst0=0;
end


always @(negedge clk or posedge rst0)
	if( rst0 ) begin
    	clkcnt <= 2'd0;
    	clk_en <= 1'b0;
    end
    else begin
    	if ( clkcnt== 2'b1 ) begin
        	clkcnt <= 2'd0;
        	clk_en <= 1'b1;
        end
        else begin
        	clkcnt <= clkcnt+1'b1;
        	clk_en <= 1'b0;
        end
    end

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
	.clk	( clk	),
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
wire signed [11:0] snd_left, snd_right;

wire irq_n = 1'b1;

jt12 uut(
	.rst		( rst	),
	.clk		( clk	),
	.cen		( 1'b1	),
	.din		( din	),
	.addr		( addr	),
	.cs_n		( cs_n	),
	.wr_n		( wr_n	),

	.limiter_en( 1'b1 ),

	.dout		( dout	),
	.irq_n		( irq_n	),
	// 1 bit output per channel at 1.3MHz
	.snd_left	( snd_left	),
	.snd_right	( snd_right	),
	// unused outputs
	.snd_sample(),
	.mux_right(),
	.mux_left(),
	.mux_sample()
);

`ifdef DUMPSOUND
initial $display("DUMP START");
`endif

endmodule
