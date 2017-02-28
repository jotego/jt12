`timescale 1ns / 1ps


/* This file is part of JT12.

 
	JT12 program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	JT12 program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with JT12.  If not, see <http://www.gnu.org/licenses/>.

	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: 27-1-2017	
	
	Each channel can use the full range of the DAC as they do not
	get summed in the real chip.

*/



`timescale 1ns / 1ps

module jt12_acc
(
	input				rst,
    input				clk,
	input signed [8:0]	op_result,
	input		 [ 1:0]	rl,
	// note that the order changes to deal 
	// with the operator pipeline delay
	input 				s1_enters,
	input 				s2_enters,
	input 				s3_enters,
	input 				s4_enters,
	input				ch6op,
	input	[2:0]		alg,
	input				pcm_en,	// only enabled for channel 6
	input	[8:0]		pcm,
	// combined output
	output reg signed	[11:0]	left,
	output reg signed	[11:0]	right,
	output 				sample,
	// multiplexed output
	output reg signed	[8:0]	mux_left,
	output reg signed	[8:0]	mux_right,	
	output				mux_sample
);

reg signed [11:0] pre_left, pre_right;

reg sum_en;

always @(*) begin
	case ( alg )
        default: sum_en <= s4_enters;
    	3'd4: sum_en <= s2_enters | s4_enters;
        3'd5,3'd6: sum_en <= ~s1_enters;        
        3'd7: sum_en <= 1'b1;
    endcase
end
   
reg sum_all;
assign sample = ~sum_all;

wire [8:0] buffer;
reg  [8:0] buffer2;
reg  [8:0] buf_mux_left;
reg	 [1:0] rl2;
reg		   last_s1;
reg  [1:0] mux_cnt;

wire signed [11:0] total_signext = { {3{total[8]}}, total };

always @(posedge clk) begin : mux_dac_input
	buffer2 <= buffer;
	rl2     <= rl;
	last_s1 <= s1_enters;
	mux_cnt <= last_s1 && s3_enters ? 2'd01 : mux_cnt + 1'b1;
	if( !mux_cnt[1] )
		buf_mux_left <= rl2[1] ? buffer2 : 9'd0;
	else begin
		mux_left <= buf_mux_left;
		mux_right <= rl[1] ? buffer : 9'd0;
	end
	
end

always @(posedge clk) begin
	if( rst ) begin
		sum_all <= 1'b0;
	end
    else begin
		if( s3_enters )  begin
    		sum_all <= 1'b1;
	        if( !sum_all ) begin
				pre_right <= rl[0] ? total_signext : 12'd0;
    		    pre_left  <= rl[1] ? total_signext : 12'd0;
	        end
        	else begin
    	    	pre_right <= pre_right + (rl[0] ? total_signext : 12'd0);
	            pre_left  <= pre_left  + (rl[1] ? total_signext : 12'd0);
        	end
		end
        if( s2_enters ) begin
        	sum_all <= 1'b0;
			left  <= pre_left;
			right <= pre_right;
            `ifdef DUMPSOUND
            $strobe("%d\t%d", left, right);
            `endif
        end
    end
end
			
reg  signed [8:0] next, opsum, prev;
wire signed [8:0] total;
wire signed [9:0] opsum10 = next+total;

always @(*) begin
	next <= sum_en ? op_result : 9'd0;
	if( s3_enters )
		opsum <= (ch6op && pcm_en) ? pcm : next;
	else begin
		if( sum_en && !(ch6op && pcm_en) )
			opsum <= opsum10[8:0]; // MSB is discarded according to
			// YM3438 application notes
		else
			opsum <= total;
	end
end

jt12_sh #(.width(9),.stages(6)) u_acc(
	.clk	( clk	),
	.din	( opsum	),
	.drop	( total	)
);

jt12_sh #(.width(9),.stages(6)) u_buffer(
	.clk	( clk	),
	.din	( s3_enters ? total : buffer	),
	.drop	( buffer	)
);

endmodule
