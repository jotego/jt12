`timescale 1ns / 1ps

module jt12_test;

`include "../common/dump.vh"

reg			clk;
reg	[1:0] ov;
reg  [ 2:0] volume;
reg  signed [13:0] pre;
wire signed [15:0] post;

initial begin
	clk = 0;
	forever #10 clk = ~clk;
end

initial begin
	pre = 0;
	volume = 0;
	ov = 0;
	forever #10 {ov, volume,pre}={ov[0], volume,pre}+1;
end

always @(*)
	if( ov[1] ) #100 $finish;

jt12_amp u_amp(
	.clk	( clk 		),
	.sample	( 1'b1		),
	.volume	( volume	),

	.pre	( pre		),	
	.post	( post		)
);

endmodule
