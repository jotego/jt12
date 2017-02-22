`timescale 1ns / 1ps

module jt12_test;

reg	rst;
reg	clk;

wire s1_enters, s2_enters, s3_enters, s4_enters;

`include "../common/dump.vh"

initial begin
	clk = 0;
    forever #10 clk=~clk;
end

reg	test_eg;
// envelope configuration
reg		[10:0]	fnum;
reg		[ 2:0]	block;
reg		[ 3:0]	mul_V;
reg		[ 2:0]	dt1_II; // same as JT51's DT1
reg				keyon_VI;


initial begin
	rst = 0;
	fnum  = 11'd500;
	block = 3'd2;
	mul_V = 5'd1;	
	dt1_II= 3'd0;
    #5 rst = 1;
    #20 rst = 0;
    #(1*1000*1000) $finish;
end

integer cycles;
reg [4:0] cnt24;
wire	zero = cnt24==5'd0;
reg keyon_done;

always @(posedge clk)
	if( rst ) begin
		cycles <= 0;
		keyon_VI <= 1'b0;
	end else begin
		cycles <= cycles + 1;
		if( cycles==100 ) keyon_VI<=1'b1;
		if( cycles==101 ) keyon_VI<=1'b0;
	end
		

always @(posedge clk)
	if( rst ) begin
		cnt24 <= 0;
	end else begin
		if( cnt24 == 5'd23 )
			cnt24 <= 5'd0;
		else
			cnt24 <= cnt24 + 1;
	end


wire 	[ 9:0]	phase_VIII;

jt12_pg u_uut(
	.clk		( clk			),
	// Channel frequency
	.fnum		( fnum			),
	.block		( block			),
	// Operator multiplying
	.mul_V		( mul_V 		),
	// Operator detuning
	.dt1_II		( dt1_II 		), // same as JT51's DT1
	// phase operation
	.keyon_VI	( keyon_VI 		),
	.keycode_III( keycode_III	),
	.phase_VIII	( phase_VIII 	)
);

wire [9:0] phase_ch0op0;
wire [9:0] rest_and, rest_or;

jt12_opsync u_opsync(
	.rst	( rst		),
	.clk	( clk		),
    .clk6   ( clk6      ),
	.s1_enters	( s1_enters ),
	.s2_enters	( s2_enters ),
	.s3_enters	( s3_enters ),
	.s4_enters	( s4_enters )
);    

sep24 #(.width(10),.pos0(7)) sep(
	.clk	( clk	),
	.mixed	( phase_VIII	),
	.cnt	( cnt24	),
	.ch0op0	( phase_ch0op0	),
	.alland	( rest_and ),
	.allor	( rest_or  ),
	.mask	( ~24'b1 )
);

endmodule
