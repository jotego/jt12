`timescale 1ns / 1ps

module jt12_dac2_tb;

wire dout;
reg rst, clk;

integer w;

initial begin
	$dumpfile("output.lxt");
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

jt12_dac2 #(.width(12)) uut
(
	.clk( clk ),
	.rst( rst ),
	.din( 12'h100 ),
	.dout( dout )
);

wire [4:0] syn_sinc1;
wire [8:0] syn_sinc2;
wire [13:0] syn_sinc3;
wire signed [13:0] sinc;

sincf #(.win(1), .wout(5)) sinc1(
	.clk ( clk ),
	.din ( dout ),
	.dout( syn_sinc1 )
);

sincf #(.win(5), .wout(9)) sinc2(
	.clk ( clk ),
	.din ( syn_sinc1 ),
	.dout( syn_sinc2 )
);

sincf #(.win(9), .wout(14)) sinc3(
	.clk ( clk ),
	.din ( syn_sinc2-9'd32 ),
	.dout( syn_sinc3 )
);

assign sinc = (syn_sinc3 + 14'd2048) ^ 14'h2000;

endmodule
