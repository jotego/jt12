module eg_comb(
	input [ 2:0] state,
	input [ 5:0] arate,
	input [ 4:0] base_rate,
	input [ 4:0] keycode,
	input [14:0] eg_cnt,
	input [ 2:0] cnt_in,
	input [ 1:0] ks,
	input [ 9:0] eg_in,
	input [ 6:0] lfo_mod,
	input        amsen,
	input [ 1:0] ams,
	input [ 6:0] tl,
	output reg   sum_up,
	output reg	[ 9:0]	eg_limited	
);

localparam ATTACK=3'd0, DECAY1=3'd1, DECAY2=3'd2, RELEASE=3'd7, HOLD=3'd3;

reg ar_off;

always @(*) ar_off = arate == 5'h1f;

reg		[6:0]	pre_rate;
reg		[5:0]	rate;

always @(*) begin : pre_rate_calc
	if( base_rate == 5'd0 )
		pre_rate = 7'd0;
	else
		case( ks )
			2'd3:	pre_rate = { base_rate, 1'b0 } + { 1'b0, keycode };
			2'd2:	pre_rate = { base_rate, 1'b0 } + { 2'b0, keycode[4:1] };
			2'd1:	pre_rate = { base_rate, 1'b0 } + { 3'b0, keycode[4:2] };
			2'd0:	pre_rate = { base_rate, 1'b0 } + { 4'b0, keycode[4:3] };
		endcase
end

always @(*)
	rate = pre_rate[6] ? 6'd63 : pre_rate[5:0];

reg		[2:0]	cnt;

always @(*) 
	if( state == ATTACK )
		case( rate[5:2] )
			4'h0: cnt = eg_cnt[13:11];
			4'h1: cnt = eg_cnt[12:10];
			4'h2: cnt = eg_cnt[11: 9];
			4'h3: cnt = eg_cnt[10: 8];
			4'h4: cnt = eg_cnt[ 9: 7];
			4'h5: cnt = eg_cnt[ 8: 6];
			4'h6: cnt = eg_cnt[ 7: 5];
			4'h7: cnt = eg_cnt[ 6: 4];
			4'h8: cnt = eg_cnt[ 5: 3];
			4'h9: cnt = eg_cnt[ 4: 2];
			4'ha: cnt = eg_cnt[ 3: 1];
			default: cnt = eg_cnt[ 2: 0];
		endcase
	else
		case( rate[5:2] )
			4'h0: cnt = eg_cnt[14:12];
			4'h1: cnt = eg_cnt[13:11];
			4'h2: cnt = eg_cnt[12:10];
			4'h3: cnt = eg_cnt[11: 9];
			4'h4: cnt = eg_cnt[10: 8];
			4'h5: cnt = eg_cnt[ 9: 7];
			4'h6: cnt = eg_cnt[ 8: 6];
			4'h7: cnt = eg_cnt[ 7: 5];
			4'h8: cnt = eg_cnt[ 6: 4];
			4'h9: cnt = eg_cnt[ 5: 3];
			4'ha: cnt = eg_cnt[ 4: 2];
			4'hb: cnt = eg_cnt[ 3: 1];
			default: cnt = eg_cnt[ 2: 0];
		endcase

////////////////////////////////
reg step;
reg [7:0] step_idx;

always @(*) begin : rate_step
	if( rate[5:4]==2'b11 ) begin // 0 means 1x, 1 means 2x
		if( rate[5:2]==4'hf && state == ATTACK)
			step_idx = 8'b11111111; // Maximum attack speed, rates 60&61
		else
		case( rate[1:0] )
			2'd0: step_idx = 8'b00000000;
			2'd1: step_idx = 8'b10001000; // 2
			2'd2: step_idx = 8'b10101010; // 4
			2'd3: step_idx = 8'b11101110; // 6
		endcase
	end
	else begin
		if( rate[5:2]==4'd0 && state != ATTACK)
			step_idx = 8'b11111110; // limit slowest decay rate
		else
		case( rate[1:0] )
			2'd0: step_idx = 8'b10101010; // 4
			2'd1: step_idx = 8'b11101010; // 5
			2'd2: step_idx = 8'b11101110; // 6
			2'd3: step_idx = 8'b11111110; // 7
		endcase
	end
	// a rate of zero keeps the level still
	step = rate[5:1]==5'd0 ? 1'b0 : step_idx[ cnt ];
end

always @(*) begin
	sum_up = cnt[0] != cnt_in;
end


//////////////////////////////////////////////////////////////
reg [3:0] 	preatt;
reg [5:0] 	att;
wire		ssg_en;
reg	[10:0]	egatt;

always @(*) begin
	case( rate[5:2] )
		4'b1100: preatt = { 2'b0, step, ~step }; // 12
		4'b1101: preatt = { 1'b0, step, ~step, 1'b0 }; // 13
		4'b1110: preatt = { step, ~step, 2'b0 }; // 14
		4'b1111: preatt = 4'd8;// 15
		default: preatt = { 2'b0, step, 1'b0 };
	endcase
	att = { 2'd0, preatt };
	egatt = {4'd0, att} + eg_in;
end

reg [8:0] ar_sum0;
reg [9:0] ar_result, ar_sum;

always @(*) begin : ar_calculation
	casez( rate[5:2] )
		default: ar_sum0 = {2'd0, eg_in[9:4]} + 8'd1;
		4'b1100: ar_sum0 = {2'd0, eg_in[9:4]} + 8'd1;
		4'b1101: ar_sum0 = {1'd0, eg_in[9:3]} + 8'd1;
		4'b111?: ar_sum0 = eg_in[9:2] + 8'd1;
	endcase
	if( rate[5:4] == 2'b11 )
		ar_sum = step ? { ar_sum0, 1'b0 } : { 1'b0, ar_sum0 };
	else
		ar_sum = step ? { 1'b0, ar_sum0 } : 10'd0;
	ar_result = ar_sum<eg_in ? eg_in-ar_sum : 10'd0;
end

reg [9:0] eg_pure;

always @(*) begin
	if( ar_off ) begin
		eg_pure = 10'd0;
	end
	else
	if( state == ATTACK ) begin
		if( sum_up && eg_in != 10'd0 )
			if( rate[5:1]==5'h1f )
				eg_pure = 10'd0;
			else
				eg_pure = ar_result;
		else
			eg_pure = eg_in;
	end
	else begin : DECAY_SUM
		if( sum_up ) begin
			if ( egatt<= 11'd1023 )
				eg_pure = egatt[9:0];
			else eg_pure = 10'h3FF;
		end
		else eg_pure = eg_in;
	end
end

//////////////////////////////////////////////////////////////
reg	[ 8:0]	am_final;
reg	[10:0]	sum_eg_tl;
reg	[11:0]	sum_eg_tl_am;
reg	[ 5:0]	am_inverted;

always @(*) begin
	am_inverted = {6{lfo_mod[6]}} ^ lfo_mod[5:0];
end

always @(*) begin
	casez( {amsen, ams } )
		default: am_final = 9'd0;
		3'b1_01: am_final = { 5'd0, am_inverted[5:2]	};
		3'b1_10: am_final = { 3'd0, am_inverted 		};
		3'b1_11: am_final = { 2'd0, am_inverted, 1'b0	};
	endcase
	sum_eg_tl = {  tl,   3'd0 } + eg_pure;
	sum_eg_tl_am = sum_eg_tl + { 3'd0, am_final };
end

always @(*)  
	eg_limited = sum_eg_tl_am[11:10]==2'd0 ? sum_eg_tl_am[9:0] : 10'h3ff;


endmodule // eg_comb