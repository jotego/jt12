`timescale 1ns / 1ps

module jt12_test;

reg [9:0] phase;
reg rst,clk;

reg [2:0] alg;

`include "../common/dump.vh"

initial begin
	clk = 0;
    forever #10 clk=~clk;
end

wire signed [13:0] left, right;
wire signed [8:0] op_result;
wire	   clk6;

wire [9:0] eg_atten;
reg [2:0] ch;
reg [2:0] voice_fb;

always @(posedge clk)
	if( rst || clk6 || ch==3'd5 ) ch <= 3'd0;
    else ch <= ch + 1'b1;
    
always @(posedge clk)
	if( rst ) phase <= 10'h3ff;
    else if(clk6) phase <= phase + 1'd1;

wire s1_enters, s2_enters, s3_enters, s4_enters;

// Ch 0 attenuation gets evaluated
// on register cycle 3, which is ch 2 at the input
wire eg_ch0 = ch==3'd2;
wire eg_ch1 = ch==3'd3;
wire eg_ch2 = ch==3'd4;
wire eg_ch3 = ch==3'd5;
wire eg_ch4 = ch==3'd0;
wire eg_ch5 = ch==3'd1;

wire eg_s1 = s3_enters;
wire eg_s3 = s2_enters;
wire eg_s2 = s4_enters;
wire eg_s4 = s1_enters;

reg [7:0] eg_max;
//assign eg_atten = eg_ch0 && (eg_s3||eg_s4) ? { 2'b0, eg_max } : 10'h3ff;
//assign eg_atten = eg_ch0 && (~eg_s4) ? { 2'b0, eg_max } : 10'h3ff;
//assign eg_atten = eg_ch0 && (eg_s1||eg_s2||eg_s4) ? { 2'b0, eg_max } : 10'h3ff;
 assign eg_atten = eg_ch0 ? { 2'b0, eg_max } : 10'h3ff;

initial begin
	rst = 0;
    alg = 3'd0;
    #5 rst = 1;
    #20 rst = 0;
    #3000000 $finish;
end

integer clk_count;

always @(posedge clk)
	if( rst ) begin
		clk_count <= 0;
	    voice_fb  <= 3'd0;
		eg_max    <= 8'd0;
	end else begin		
		if( !clk_count[6:0] ) eg_max <= eg_max + 1'b1;
		if( clk_count == 30000 ) begin
			voice_fb <= voice_fb + 3'd1;
			clk_count <= 0;
		end
		else clk_count <= clk_count+1;
	end
	


jt12_opsync u_opsync(
	.rst	( rst		),
	.clk	( clk		),
    .clk6   ( clk6      ),
	.s1_enters	( s1_enters ),
	.s2_enters	( s2_enters ),
	.s3_enters	( s3_enters ),
	.s4_enters	( s4_enters )
);    

jt12_fm u_fm(
	.alg_st1	( alg		),
	.s1_enters	( s1_enters ),
	.s2_enters	( s2_enters ),
	.s3_enters	( s3_enters ),
	.s4_enters	( s4_enters ),
    
	.use_prevprev1 ( use_prevprev1  ),
	.use_internal_x( use_internal_x ),
	.use_internal_y( use_internal_y ),    
	.use_prev2     ( use_prev2      ),
	.use_prev1     ( use_prev1      )
);

reg s1_delayed;

always @(posedge clk)
	s1_delayed <= s1_enters;

jt12_op u_op(
	.rst		( rst	),
	.clk		( clk	),
	.pg_phase	( phase	),
	.eg_atten	( eg_atten	),
	.voice_fb	( voice_fb	),
	.op_fb_enable	( s1_delayed		),

	.test_214		( 1'b0		),
	.s1_enters		( s1_enters ),
	.s2_enters		( s2_enters ),
	.s3_enters		( s3_enters ),
	.s4_enters		( s4_enters ),
	.use_prevprev1	( use_prevprev1 ),
	.use_internal_x	( use_internal_x),
	.use_internal_y	( use_internal_y),
	.use_prev2		( use_prev2		),
	.use_prev1		( use_prev1		),

	.op_result		( op_result		)
);

jt12_acc u_acc(
	.rst		( rst	),
	.clk		( clk	),
	.op_result	( op_result		),
	.rl			( 2'b11	),
	// note that the order changes to deal 
	// with the operator pipeline delay
	.s1_enters		( s2_enters ),
	.s2_enters		( s1_enters ),
	.s3_enters		( s4_enters ),
	.s4_enters		( s3_enters ),	
	.alg			( alg		),
	.left			( left		),
	.right			( right		)
);

endmodule
