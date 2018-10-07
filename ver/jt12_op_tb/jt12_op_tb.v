`timescale 1ns / 1ps

module jt12_op_tb;

reg	[9:0]	pg_phase;
reg	[9:0]	eg_atten;
reg	[2:0]	voice_fb;
reg			op_fb_enable;
reg	[5:0]	op_algorithm_ctl;
reg			test_214;

wire signed [13:0]	op_result;

reg			clk, rst;

reg	signed [13:0]	op0;

integer		count;
reg [2:0] count6;

reg	[1:0]	op_count;

initial begin
	$dumpfile("jt12_op_tb.lxt");
	$dumpvars();
	$dumpon;
end

initial begin
	clk = 1'b0;
	forever #10 clk = ~clk;
end

initial begin
	rst = 1'b1;
	#405 rst = 1'b0;
end

reg [5:0] algctl [3:0];

initial begin
	algctl[0] = 6'h00;
	algctl[1] = 6'h01;
	algctl[2] = 6'h00;
	algctl[3] = 6'h10;			
end

always @(posedge count6) begin
	algctl[3] <= algctl[0];
	algctl[2] <= algctl[3];
	algctl[1] <= algctl[2];
	algctl[0] <= algctl[1];
end
	
// reg clean_pipeline;

always @(posedge clk or rst) 
	if( rst ) begin
		pg_phase <= 10'd0;
		eg_atten <= 10'd0;
		voice_fb <= 3'd0;
		op_fb_enable <= 1'b1;
		op_algorithm_ctl <= 6'd4;
		test_214 <= 1'b0;
		count	 <= 0;
		count6	 <= 0;
		op0		 <= 14'd0;
		op_count <= 2'd0;
//		clean_pipeline <= 1'b1;
	end
	else begin
		count	 <= count + 1;
//		if( count == 4*6*20 ) clean_pipeline <= 1'b0; 
		if( count == 6*2048 ) $finish;
		if( count6<5 ) count6<=count6+1; else count6<=0;
		if( count6==0 ) begin
			op0 <= op_result;
			op_count <= op_count +1'd1;
			pg_phase <= pg_phase + 1'b1;
		end
	end

jt12_op #(.NUM_VOICES(6)) uut(
	.rst			( rst		),
    .clk			( clk 		),
    .clk_en			( 1'b1		),
    .pg_phase_VIII	( count6==0 ? pg_phase : 10'd0 ),
    .eg_atten_IX	( eg_atten	),		// output from envelope generator
    .fb_II			( voice_fb	),		// voice feedback
    .op_fb_enable(op_count==2'd0 ),	// feedback enable
    .op_algorithm_ctl( count6==0? algctl[0] : 6'd0 ),	// Algorithm control
    .test_214	( test_214	),
    
    .op_result	( op_result	)
);


endmodule
