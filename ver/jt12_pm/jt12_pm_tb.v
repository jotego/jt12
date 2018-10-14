
`timescale 1ns / 1ps

module jt12_pm_tb;

reg [4:0] lfo_mod=5'd0;
reg [10:0] fnum = 11'd1;
reg clk;
reg [2:0] pms=3'd0;

initial begin
	clk = 1'b0;
	forever clk = #10 ~clk;
end // initial

reg finish=1'b0;

always @(posedge clk) begin
	lfo_mod <= lfo_mod + 1'd1;
	if( &lfo_mod ) pms<=pms+3'd1;
	if( &{lfo_mod, pms} ) { finish, fnum} <= { fnum, 1'b0 };
	if( finish ) $finish;
	$display("%d\t%d\t0x%X\t%d",lfo_mod,pms,fnum,pm_offset);
end

// initial begin
// 	$dumpfile("jt12_pm_tb.lxt");
// 	$dumpvars;
// 	$dumpon;
// end

wire signed [7:0] pm_offset;

jt12_pm uut (
	.lfo_mod( lfo_mod ),
	.pms(pms),
	.fnum( fnum ),
	.pm_offset( pm_offset )
);

endmodule // jt12_pm