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

module jt12_fir
#(parameter data_width=9, extra=3)
(
	input	clk,	// Use clk_out from jt12, this is x24 higher than
	input	rst,
	input	sample,
	input	signed [data_width-1:0] din,
	output	reg signed [data_width*2+1:0] dout
);

parameter coeff_width=9;
parameter stages=73;

reg signed [coeff_width-1:0] coeff[0:(stages-1)/2];
reg signed [11:0] chain[0:stages-1];

reg update, last_sample;

always @(posedge clk)
	if( rst )
		{ update, last_sample } <= 2'b00;
	else begin
		last_sample <= sample;
		update <= sample && !last_sample;
	end

// shift register
genvar i;
generate
	for (i=0; i < stages; i=i+1) begin: bit_shifter
		always @(posedge clk)
			if( update )
				if(i>0) chain[i] <= chain[i-1];
				else chain[0] <= din;
	end
endgenerate

parameter mac_width=data_width+coeff_width+1;
parameter acc_width=mac_width+3;
reg	signed [acc_width-1:0] acc;
reg signed [mac_width-1:0] mac;
//integer acc,mac;
reg [5:0] 	cnt;
reg [6:0]   rev;
reg	[1:0]	state;

parameter IDLE=2'b00, BUSY=2'b01, RELEASE=2'b10;

reg signed [data_width:0] sum;

wire last_stage = cnt==(stages-1)/2;

//integer a,b;

always @(*) begin
	sum <= chain[cnt] +
			( last_stage ? {data_width{1'b0}}:chain[rev]);
	mac <= coeff[cnt]*sum;
end

wire [data_width-1:0] ch0, ch72, ch1, ch71, ch2, ch70, ch3, ch69;

assign ch0 = chain[0];
assign ch72 = chain[72];
assign ch1 = chain[1];
assign ch71 = chain[71];
assign ch2 = chain[2];
assign ch70 = chain[70];
assign ch3 = chain[3];
assign ch69 = chain[69];

always @(posedge clk)
if( rst ) begin
	cnt <= 6'd0;
	rev <= 6'd0;
	acc <= {acc_width{1'b0}};
	mac <= {acc_width{1'b0}};
	dout<= {data_width+extra{1'b0}};
end else begin
	case(state)
		default:
			if( update ) begin
				cnt <= 6'd0;
				rev <= stages-1;
				acc <= {acc_width{1'b0}};
				mac <= {acc_width{1'b0}};
				state <= BUSY;
			end
		BUSY: begin
				acc <= acc + mac;
				if( cnt==(stages-1)/2 )
					state<=RELEASE;
				else begin
					cnt<=cnt+1'b1;
					rev<=rev-1'b1;
				end
			end
		RELEASE: begin
			dout <= acc; //acc + mac;
			state <= IDLE;
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
