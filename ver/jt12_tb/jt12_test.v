`timescale 1ns / 1ps

module jt12_test;

reg	rst;

`ifndef DUMPLFO
`ifndef KEYON_TEST
`include "../common/dump.vh"
`endif
`endif

`ifdef KEYON_TEST
initial begin
	$dumpfile("jt12_test.lxt");
	$dumpvars(1, jt12_test.uut.u_op );
	$dumpvars(1, jt12_test.uut.u_eg );
	$dumpvars(1, jt12_test.uut.u_mmr.u_reg.u_kon );
	$dumpon;
end
`endif

`ifdef DUMPLFO
initial begin
	$dumpfile("jt12_test.lxt");
	$dumpvars(0, jt12_test.uut.u_lfo );
	$dumpon;
end
`endif

/*
reg	clk;
initial begin
	clk = 0;
    forever #62.5 clk=~clk;
end
*/

reg mclk;

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



initial begin
	rst = 0;
    #500 rst = 1;
    #600 rst = 0;
	`ifdef LIMITTIME
	#(`LIMITTIME*1000*1000) $finish;
    `endif
end


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
wire signed [8:0] mux_left, mux_right;

jt12 uut(
	.rst	( rst	),
	.clk	( clk	),
	.din	( din	),
	.addr	( addr	),
	.cs_n	( cs_n	),
	.wr_n	( wr_n	),

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

wire signed [15:0] ampleft7, ampright7;

reg [2:0] vol;

initial begin
	vol = 0;
	forever #10000000 vol=vol+1;
end

jt12_amp_stereo amp7(
	.clk	( clk 		),
	.sample	( sample	),
	.fmleft	( left		),
	.fmright( right		),
	.enable_psg( 1'b0 	),
	.psg	( 5'd0 		),
	.postleft( ampleft7	),
	.postright( ampright7	),
	.volume	( vol 		)
);

wire signed [15:0] ampleft4, ampright4;

jt12_amp_stereo amp(
	.clk	( clk 		),
	.sample	( sample	),
	.fmleft	( left		),
	.fmright( right		),
	.enable_psg( 1'b0 	),
	.psg	( 5'd0 		),
	.postleft( ampleft4	),
	.postright( ampright4	),
	.volume	( ~vol 		)
);

`ifdef DUMPSOUND
initial $display("DUMP START");
`endif

endmodule
