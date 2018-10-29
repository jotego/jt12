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
	input		[3:0]	d1l,   // sustain level

);

localparam ATTACK=3'd0, DECAY1=3'd1, DECAY2=3'd2, RELEASE=3'd7, HOLD=3'd3;

reg		[4:0]	d1level;

always @(*) if( clk_en ) begin
	if( d1l == 4'd15 )
		d1level = 5'h1f; // 93dB
	else
		d1level = {1'b0, d1l};
end

//	Register Cycle II
reg	[4:0] cfg_III;
wire	ssg_en_out;
wire	keyon_last_II;
reg		ssg_en_in_II;

wire	ar_off_II = arate_II == 5'h1f;

wire	keyon_now_II  = !keyon_last_II && keyon_II;
wire	keyoff_now_II = keyon_last_II && !keyon_II;

always @(*) begin
	// ar_off_III	<= arate_II == 5'h1f;
	// trigger release
	if( keyoff_now_II ) begin
		cfg_III <= { rrate_II, 1'b1 };
		state_III <= RELEASE;
		pg_rst_III	<= 1'b0;
		ar_off_III <= 1'b0;
	end
	else begin
		// trigger 1st decay
		if( keyon_now_II ) begin
			cfg_III <= arate_II;
			state_III <= ATTACK;
			pg_rst_III <= 1'b1;
			ar_off_III <= ar_off_II;
		end
		else begin : sel_rate
			pg_rst_III <= (eg_II==10'h3FF) ||ssg_pg_rst;
			if( (state_II==DECAY1 ||state_II==DECAY2) && ssg_en_II && eg_II >= 10'h200 ) begin
				ssg_invertion_III <= ssg_alt_II ^ ssg_invertion_II;
				if( ssg_hold_II ) begin
					cfg_III <= 5'd0;
					state_III <= HOLD; // repeats!
					ar_off_III <= 1'b0;
				end
				else begin
					cfg_III	<=	rate2_II;
					state_III <= ATTACK; // repeats!
					ar_off_III <= 1'b1;
				end
			end
			else begin
				ssg_invertion_III <= state_II==RELEASE ? 1'b0 : ssg_invertion_II;
				case ( state_II )
					ATTACK: begin
						if( eg_II==10'd0 ) begin
							state_III <= DECAY1;
							cfg_III		 <= rate1_II;
						end
						else begin
							state_III <= state_II; // attack
							cfg_III		 <= arate_II;
						end
						ar_off_III <= 1'b0;
						end
					DECAY1: begin
						if( eg_II[9:5] >= d1level ) begin
							cfg_III <= rate2_II;
							state_III <= DECAY2;
						end
						else begin
							cfg_III	<=	rate1_II;
							state_III <= state_II;	// decay1
						end
						ar_off_III <= 1'b0;
						end
					DECAY2:
						begin
							cfg_III	<=	rate2_II;
							state_III <= state_II;	// decay2
							ar_off_III <= 1'b0;
						end
					RELEASE: begin
							cfg_III	<=	{ rrate_II, 1'b1 };
							state_III <= state_II;	// release
							ar_off_III <= 1'b0;
						end
					HOLD: begin
							cfg_III <= 5'd0;
							state_III <= HOLD; // repeats!
							ar_off_III <= 1'b0;
						end
					default:;
				endcase
			end
		end
	end

	eg_III <= eg_II;
end


endmodule // jt12_eg_ctrl