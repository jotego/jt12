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
	#(60*1000*1000) $finish;
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

wire	sample;

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
	.preleft( { left, 2'd0}		),
	.preright({ right, 2'd0}	),
	.postleft( ampleft7	),
	.postright( ampright7),
	.volume( vol 		)
);

wire signed [15:0] ampleft4, ampright4;

jt12_amp_stereo amp(
	.clk	( clk 		),
	.sample	( sample	),
	.preleft( { left, 2'd0}		),
	.preright({ right, 2'd0}	),
	.postleft( ampleft4	),
	.postright( ampright4),
	.volume( ~vol 		)
);

`ifdef DUMPSOUND
initial $display("DUMP START");
`endif

endmodule
