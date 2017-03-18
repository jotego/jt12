`timescale 1ns / 1ps

module jt12_dac_tb;

wire dout;
reg rst, clk;

integer w;

initial begin
	$dumpfile("jt12_dac_tb.lxt");
	$dumpvars;
	$dumpon;
	rst = 1;
	#55 rst = 0;
	for(w=0; w<1000; w=w+1) #1000;
	$finish;
end

initial begin
	clk = 0;
	forever #10 clk = ~clk;
end

jt12_dac #(.width(12)) uut
(
	.clk( clk ),
	.rst( rst ),
	.din( -12'd1023 ),
	.dout( dout )
);

real filter;

always @(posedge clk)
if ( rst )
	filter <= 0;
else begin
	if( dout )
    	filter <= filter + 9.26e-9/5e-6 * (1.0-filter);
	else
	    filter <= filter - 9.26e-9/5e-6 * filter;
end

real speaker;

reg audio_clk;

initial begin
	audio_clk = 0;
    forever #22700 audio_clk = ~audio_clk;
end

always @(posedge audio_clk)
	speaker <= 2*(filter-0.5);

endmodule
