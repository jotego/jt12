/*  This file is part of JT12.

    JT12 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT12 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT12.  If not, see <http://www.gnu.org/licenses/>.

	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: March, 7th 2017
	*/

`timescale 1ns / 1ps

module jt12_fir_ram 
#(parameter data_width=8, parameter addr_width=7)
(
	input [(data_width-1):0] data,
	input [(addr_width-1):0] addr,
	input we, clk,
	output [(data_width-1):0] q
);

	reg [data_width-1:0] ram[2**addr_width-1:0];

	always @ (posedge clk)
		if (we)
			ram[addr] <= data;
	assign q = ram[addr];
endmodule

module jt12_fir
#(parameter data_width=9, extra=3)
(
	input	clk,	// Use clk_out from jt12, this is x24 higher than
	input	rst,
	input	sample,
	input	signed [data_width-1:0] left_in,
	input	signed [data_width-1:0] right_in,
	output	reg signed [data_width*2+1:0] left_out,
	output	reg signed [data_width*2+1:0] right_out,
	output	reg sample_out
);

parameter coeff_width=9;
parameter stages=73;

reg signed [coeff_width-1:0] coeff[0:(stages-1)/2];
//reg signed [data_width-1:0] chain_left[0:stages-1];
//reg signed [data_width-1:0] chain_right[0:stages-1];
wire signed [data_width-1:0] mem_left, mem_right;
reg [6:0] addr_left, addr_right, forward, rev, in_pointer;
reg update, last_sample;

reg	[1:0]	state;
parameter IDLE=2'b00, LEFT=2'b01, RIGHT=2'b10;

always @(*) 
	case( state )
		default: begin
			addr_left <= in_pointer;
			addr_right<= in_pointer;
		end
		LEFT: begin
			addr_left <= rev;
			addr_right<= forward;
		end
		RIGHT: begin
			addr_left <= forward;
			addr_right<= rev;
		end
	endcase

jt12_fir_ram #(.data_width(data_width),.addr_width(7)) chain_left(
	.clk	( clk		),
	.data	( left_in 	),
	.addr	( addr_left ),
	.we		( update	),
	.q		( mem_left	)
);

jt12_fir_ram #(.data_width(data_width),.addr_width(7)) chain_right(
	.clk	( clk		),
	.data	( right_in 	),
	.addr	( addr_right),
	.we		( update	),
	.q		( mem_right)
);
	

always @(posedge clk)
	if( rst )
		{ update, last_sample } <= 2'b00;
	else begin
		last_sample <= sample;
		update <= sample && !last_sample;
	end

parameter mac_width=data_width+coeff_width+1;
parameter acc_width=mac_width+3;
reg	signed [acc_width-1:0] acc_left, acc_right;
reg signed [mac_width-1:0] mac;
//integer acc,mac;
reg [5:0] 	cnt, next;

reg signed [data_width:0] sum;
reg signed [coeff_width-1:0] gain;

wire last_stage = cnt==(stages-1)/2;

//integer a,b;

always @(*) begin
	if( state==LEFT) begin	
		if( last_stage )
			sum <= buffer_left;
		else
			sum <= buffer_left + mem_left;
		end
	else begin
		if( last_stage )
			sum <= buffer_right;
		else
			sum <= buffer_right + mem_right;
	end
	gain <= coeff[cnt];
	mac <= gain*sum;
	next <= cnt+1'b1;
end

reg signed [data_width-1:0] buffer_left, buffer_right;

always @(posedge clk)
if( rst ) begin
	sample_out <= 1'b0;
	state	<= IDLE;
	in_pointer <= 7'd0;
end else begin
	case(state)
		default: begin
			if( update ) begin
				cnt <= 6'd0;
				acc_left <= {acc_width{1'b0}};
				acc_right <= {acc_width{1'b0}};
				state <= LEFT;
				buffer_left <= left_in;
				rev <= in_pointer+stages-1'b1;
				forward <= in_pointer;
			end
			sample_out <= 1'b0;
		end
		LEFT: begin
				acc_left <= acc_left + mac;
				buffer_right <= mem_right;
				forward<=forward + 1'b1;
				state <= RIGHT;
			end
		RIGHT:
			if( cnt==(stages-1)/2 ) begin
				left_out  <= acc_left;
				right_out <= acc_right+mac;
				sample_out <= 1'b1;
				in_pointer  <= in_pointer - 1'b1;
				state <= IDLE;
			end else begin
				acc_right <= acc_right + mac;
				buffer_left <= mem_left;
				cnt<=next;
				rev<=rev-1'b1;
				state <= LEFT;
			end
	endcase
end


initial begin
        coeff[0] <= -9'd0;
        coeff[1] <= -9'd1;
        coeff[2] <= -9'd1;
        coeff[3] <= -9'd2;
        coeff[4] <= -9'd3;
        coeff[5] <= -9'd3;
        coeff[6] <= -9'd4;
        coeff[7] <= -9'd4;
        coeff[8] <= -9'd3;
        coeff[9] <= -9'd1;
        coeff[10] <= 9'd1;
        coeff[11] <= 9'd3;
        coeff[12] <= 9'd7;
        coeff[13] <= 9'd10;
        coeff[14] <= 9'd12;
        coeff[15] <= 9'd13;
        coeff[16] <= 9'd12;
        coeff[17] <= 9'd9;
        coeff[18] <= 9'd3;
        coeff[19] <= -9'd5;
        coeff[20] <= -9'd14;
        coeff[21] <= -9'd24;
        coeff[22] <= -9'd33;
        coeff[23] <= -9'd40;
        coeff[24] <= -9'd43;
        coeff[25] <= -9'd39;
        coeff[26] <= -9'd29;
        coeff[27] <= -9'd12;
        coeff[28] <= 9'd13;
        coeff[29] <= 9'd44;
        coeff[30] <= 9'd80;
        coeff[31] <= 9'd119;
        coeff[32] <= 9'd157;
        coeff[33] <= 9'd192;
        coeff[34] <= 9'd222;
        coeff[35] <= 9'd243;
        coeff[36] <= 9'd255;
end

endmodule
