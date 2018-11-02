module jt12_pg_inc (
	input		[ 2:0]	block,
	input		[ 2:0]	detune,
	input		[ 3:0]	mul,
	input		[10:0]	fnum,
	input		[19:0]	phase_in,
	input				pg_rst,
	input signed [7:0]	pm_offset,

	output reg	[ 4:0]	keycode,
	output reg	[19:0]	phase_out,
	output reg	[ 9:0]	phase_op
);

reg [ 5:0] detune_kf;
reg [16:0] phinc_pure;

always @(*) begin 
	keycode	= { block, fnum[10], fnum[10] ? (|fnum[9:7]) : (&fnum[9:7])};
	case( detune[1:0] )
		2'd1:	detune_kf	=	{ 1'b0, keycode } - 6'd4;
		2'd2:	detune_kf	=	{ 1'b0, keycode } + 6'd4;
		2'd3:	detune_kf	=	{ 1'b0, keycode } + 6'd8;
		default:detune_kf	=	{ 1'b0, keycode };
	endcase
	case ( block )
		3'd0: phinc_pure = { 7'd0, fnum[10:1] };
		3'd1: phinc_pure = { 6'd0, fnum[10:0] };
		3'd2: phinc_pure = { 5'd0, fnum, 1'd0 };
		3'd3: phinc_pure = { 4'd0, fnum, 2'd0 };
		3'd4: phinc_pure = { 3'd0, fnum, 3'd0 };
		3'd5: phinc_pure = { 2'd0, fnum, 4'd0 };
		3'd6: phinc_pure = { 1'd0, fnum, 5'd0 };
		3'd7: phinc_pure = {       fnum, 6'd0 };
	endcase
end

reg [ 4:0] pow2;
reg [5:0] detune_unlimited;
reg [4:0] detune_limit, detune_limited;
reg signed [5:0] detune_signed;

always @(*) begin : calcpow2
	case( detune_kf[2:0] )
		3'd0: pow2 = 5'd16;
		3'd1: pow2 = 5'd17;
		3'd2: pow2 = 5'd19;
		3'd3: pow2 = 5'd20;
		3'd4: pow2 = 5'd22;
		3'd5: pow2 = 5'd24;
		3'd6: pow2 = 5'd26;
		3'd7: pow2 = 5'd29;
	endcase
	case( detune[1:0] )
		2'd0: detune_limit = 5'd0;
		2'd1: detune_limit = 5'd8;
		2'd2: detune_limit = 5'd16;
		2'd3: detune_limit = 5'd22;
	endcase
	case( detune_kf[5:3] )
		3'd0:	detune_unlimited = { 5'd0, pow2[4]   }; // <2
		3'd1:	detune_unlimited = { 4'd0, pow2[4:3] }; // <4
		3'd2:	detune_unlimited = { 3'd0, pow2[4:2] }; // <8
		3'd3:	detune_unlimited = { 2'd0, pow2[4:1] };
		3'd4:	detune_unlimited = { 1'd0, pow2[4:0] };
		3'd5:	detune_unlimited = { pow2[4:0], 1'd0 };
		default:detune_unlimited = 6'd0;
	endcase
	detune_limited = detune_unlimited > {1'b0, detune_limit} ? 
							detune_limit : detune_unlimited[4:0];
	detune_signed = !detune[2] ? {1'b0,detune_limited} : (~{1'b0,detune_limited}+6'd1);
end

reg [19:0] phase_premul, phase_mul;

always @(*) begin
	phase_out = pg_rst ? 20'd0 : 
		(phase_in + {{3{1'b0}},phinc_pure} + 
		{{14{detune_signed[5]}},detune_signed});
	phase_premul= phase_out + {{12{pm_offset[7]}},pm_offset};
	phase_mul	= ( mul==4'd0 ) ? (phase_premul>>1) : (phase_premul * mul);
	phase_op	= phase_mul[19:10];
end

endmodule // jt12_pg_inc