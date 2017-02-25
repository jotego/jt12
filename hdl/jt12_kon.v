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

*/

module jt12_kon(
	input 			rst,
	input 			clk,
	input	[3:0]	keyon_op,
	input	[2:0]	keyon_ch,
	input	[4:0]	next_slot,
	input			up_keyon,
	input			csm,
	input			flag_A,
	input			overflow_A,
	
	output	reg		keyon_II,
	output	reg		keyoff_II,
	output	reg		busy
);

reg [23:0] kon_op, koff_op, pre_kon_op, pre_koff_op;

//assign keyon_II  = kon_op [0];
// assign keyoff_II = koff_op[0];

always @(*) begin
	// Slot 1
	pre_kon_op [ 0] <= keyon_ch==3'd0 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 0] <= keyon_ch==3'd0 ? ~keyon_op[0] : 1'b0;
	pre_kon_op [ 1] <= keyon_ch==3'd1 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 1] <= keyon_ch==3'd1 ? ~keyon_op[0] : 1'b0;
	pre_kon_op [ 2] <= keyon_ch==3'd2 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 2] <= keyon_ch==3'd2 ? ~keyon_op[0] : 1'b0;
	pre_kon_op [ 3] <= keyon_ch==3'd4 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 3] <= keyon_ch==3'd4 ? ~keyon_op[0] : 1'b0;
	pre_kon_op [ 4] <= keyon_ch==3'd5 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 4] <= keyon_ch==3'd5 ? ~keyon_op[0] : 1'b0;
	pre_kon_op [ 5] <= keyon_ch==3'd6 ?  keyon_op[0] : 1'b0;
	pre_koff_op[ 5] <= keyon_ch==3'd6 ? ~keyon_op[0] : 1'b0;
	// Slot 3
	pre_kon_op [ 6] <= keyon_ch==3'd0 ?  keyon_op[2] : 1'b0;
	pre_koff_op[ 6] <= keyon_ch==3'd0 ? ~keyon_op[2] : 1'b0;
	pre_kon_op [ 7] <= keyon_ch==3'd1 ?  keyon_op[2] : 1'b0;
	pre_koff_op[ 7] <= keyon_ch==3'd1 ? ~keyon_op[2] : 1'b0;
	pre_kon_op [ 8] <= keyon_ch==3'd2 ?  keyon_op[2] : 1'b0;
	pre_koff_op[ 8] <= keyon_ch==3'd2 ? ~keyon_op[2] : 1'b0;
	pre_kon_op [ 9] <= keyon_ch==3'd4 ?  keyon_op[2] : 1'b0;
	pre_koff_op[ 9] <= keyon_ch==3'd4 ? ~keyon_op[2] : 1'b0;
	pre_kon_op [10] <= keyon_ch==3'd5 ?  keyon_op[2] : 1'b0;
	pre_koff_op[10] <= keyon_ch==3'd5 ? ~keyon_op[2] : 1'b0;
	pre_kon_op [11] <= keyon_ch==3'd6 ?  keyon_op[2] : 1'b0;
	pre_koff_op[11] <= keyon_ch==3'd6 ? ~keyon_op[2] : 1'b0;
	// Slot 2
	pre_kon_op [12] <= keyon_ch==3'd0 ?  keyon_op[1] : 1'b0;
	pre_koff_op[12] <= keyon_ch==3'd0 ? ~keyon_op[1] : 1'b0;
	pre_kon_op [13] <= keyon_ch==3'd1 ?  keyon_op[1] : 1'b0;
	pre_koff_op[13] <= keyon_ch==3'd1 ? ~keyon_op[1] : 1'b0;
	pre_kon_op [14] <= keyon_ch==3'd2 ?  keyon_op[1] : 1'b0;
	pre_koff_op[14] <= keyon_ch==3'd2 ? ~keyon_op[1] : 1'b0;
	pre_kon_op [15] <= keyon_ch==3'd4 ?  keyon_op[1] : 1'b0;
	pre_koff_op[15] <= keyon_ch==3'd4 ? ~keyon_op[1] : 1'b0;
	pre_kon_op [16] <= keyon_ch==3'd5 ?  keyon_op[1] : 1'b0;
	pre_koff_op[16] <= keyon_ch==3'd5 ? ~keyon_op[1] : 1'b0;
	pre_kon_op [17] <= keyon_ch==3'd6 ?  keyon_op[1] : 1'b0;
	pre_koff_op[17] <= keyon_ch==3'd6 ? ~keyon_op[1] : 1'b0;
	// Slot 4
	pre_kon_op [18] <= keyon_ch==3'd0 ?  keyon_op[3] : 1'b0;
	pre_koff_op[18] <= keyon_ch==3'd0 ? ~keyon_op[3] : 1'b0;
	pre_kon_op [19] <= keyon_ch==3'd1 ?  keyon_op[3] : 1'b0;
	pre_koff_op[19] <= keyon_ch==3'd1 ? ~keyon_op[3] : 1'b0;
	pre_kon_op [20] <= keyon_ch==3'd2 ?  keyon_op[3] : 1'b0;
	pre_koff_op[20] <= keyon_ch==3'd2 ? ~keyon_op[3] : 1'b0;
	pre_kon_op [21] <= keyon_ch==3'd4 ?  keyon_op[3] : 1'b0;
	pre_koff_op[21] <= keyon_ch==3'd4 ? ~keyon_op[3] : 1'b0;
	pre_kon_op [22] <= keyon_ch==3'd5 ?  keyon_op[3] : 1'b0;
	pre_koff_op[22] <= keyon_ch==3'd5 ? ~keyon_op[3] : 1'b0;
	pre_kon_op [23] <= keyon_ch==3'd6 ?  keyon_op[3] : 1'b0;
	pre_koff_op[23] <= keyon_ch==3'd6 ? ~keyon_op[3] : 1'b0;
end

reg csm_copy;

always @(posedge clk)
	if( rst ) begin
		{ kon_op, koff_op } <= { 24'd0, ~24'd0};
		busy <= 1'b0;
		csm_copy <= 1'b0;
	end
	else
	if( busy && next_slot==5'd0) begin
		busy <= 1'b0;
		kon_op  <= csm_copy ? {24{1'b1}} : pre_kon_op;
		koff_op <= csm_copy ? {24{1'b0}} : pre_koff_op;
	end
	else begin
		if( up_keyon   ) { busy, csm_copy } <= 2'b10;
		if( overflow_A && csm ) { busy, csm_copy }  <= { 2'b11 };
		{ kon_op, keyon_II }   <= { 1'b0, kon_op [23:0] };
		{ koff_op, keyoff_II } <= { 1'b0, koff_op[23:0] };		
	end

endmodule
