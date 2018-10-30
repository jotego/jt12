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
	Date: 29-10-2018

	*/

module jt12_eg_ctrl(
	input			 	rst,
	input				keyon_now,
	input				keyoff_now,
	input		[3:0]	state_in,
	// envelope configuration	
	input		[4:0]	arate, // attack  rate
	input		[4:0]	rate1, // decay   rate
	input		[4:0]	rate2, // sustain rate
	input		[3:0]	rrate,
	input		[3:0]	d1l,   // sustain level

	output reg	[3:0]	base_rate,
	output reg			attack,
	output reg			state_next,
	output reg			pg_rst
);

localparam 	ATTACK = 3'b001, 
			DECAY1 = 3'b010, 
			DECAY2 = 3'b100, 
			RELEASE= 3'b000; // default state is release 

wire is_decaying = state_in[1] | state_in[2];

reg		[4:0]	d1level;

always @(*) if( clk_en ) begin
	if( d1l == 4'd15 )
		d1level = 5'h1f; // 93dB
	else
		d1level = {1'b0, d1l};
end

wire	ssg_en_out;
wire	keyon_last;
reg		ssg_en_in;

wire	ar_off = arate == 5'h1f;

always @(*) begin
	pg_rst = keyon_now | ssg_pg_rst;
	ssg_invertion = state[0] ? 1'b0 : ssg_invertion; // no invertion during attack
end

always @(*) begin
	// ar_off	= arate == 5'h1f;
	// trigger release
	if( keyoff_now ) begin
		base_rate = { rrate, 1'b1 };
		state_next = RELEASE;
	end
	else begin
		// trigger 1st decay
		if( keyon_now ) begin
			base_rate = arate;
			state_next = ATTACK;
		end
		else begin : sel_rate
			if( is_decaying && ssg_en && eg >= 10'h200 ) begin
				ssg_invertion = ssg_alt ^ ssg_invertion;
				if( ssg_hold ) begin
					base_rate	= 5'd0;
					state_next	= DECAY2; // it will get locked here forever (hold the value)
				end
				else begin
					base_rate  = arate;
					state_next = ATTACK; // repeats!
				end
			end
			else begin
				case ( state_in )
					ATTACK: 
						if( eg==10'd0 ) begin
							base_rate  = rate1;
							state_next = DECAY1;
						end
						else begin
							base_rate  = arate;
							state_next = ATTACK;
						end
					DECAY1: 
						if( eg[9:5] >= d1level ) begin
							base_rate  = rate2;
							state_next = DECAY2;
						end
						else begin
							base_rate	= rate1;
							state_next	= DECAY1;	// decay1
						end
					DECAY2:
						begin
							base_rate	= rate2;
							state_next	= DECAY2;	// decay2
						end
					default: begin // RELEASE
							base_rate	= { rrate, 1'b1 };
							state_next  = RELEASE;	// release
						end
				endcase
			end
		end
	end
end


endmodule // jt12_eg_ctrl