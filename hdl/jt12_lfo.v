/*  This file is part of JT51.

    JT51 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT51 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT51.  If not, see <http://www.gnu.org/licenses/>.
	
	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: 27-10-2016
	*/

`timescale 1ns / 1ps

/*

	tab size 4

*/

module jt51_lfo(
	input			 	rst,
	input			 	clk,
	input				zero,
	input				lfo_rst,
	input		[7:0]	lfo_freq,
	input		[6:0]	lfo_amd,
	input		[6:0]	lfo_pmd,	
	input		[1:0]	lfo_w,
	output	reg	[6:0]	am,
	output	reg	[7:0]	pm_u
);

reg	signed [7:0] pm;

always @(*) begin: signed_to_unsigned
	if( pm[7] ) begin
		pm_u[7] <= pm[7];
		pm_u[6:0] <= ~pm[6:0];
	end
	else pm_u <= pm;
end

wire [6:0] noise_am;
wire [7:0] noise_pm;

parameter b0=3;
reg [15+b0:0] base;

always @(posedge clk) begin : base_counter
	if( rst ) begin
		base	<= {b0+15{1'b0}};
	end
	else begin
		if( zero ) base <= base + 1'b1;
	end
end

reg sel_base;
reg [4:0] freq_sel;

always @(*) begin : base_mux
	freq_sel <= lfo_freq[7:4] 
		+ ( lfo_w==2'd2 ? 1'b1 : 1'b0 );
	case( freq_sel )
		5'h10: sel_base <= base[b0-1]; 
		5'hf: sel_base <= base[b0+0]; 
		5'he: sel_base <= base[b0+1]; 
		5'hd: sel_base <= base[b0+2]; 
		5'hc: sel_base <= base[b0+3]; 
		5'hb: sel_base <= base[b0+4]; 
		5'ha: sel_base <= base[b0+5]; 
		5'h9: sel_base <= base[b0+6]; 
		5'h8: sel_base <= base[b0+7]; 
		5'h7: sel_base <= base[b0+8]; 
		5'h6: sel_base <= base[b0+9]; 
		5'h5: sel_base <= base[b0+10]; 
		5'h4: sel_base <= base[b0+11]; 
		5'h3: sel_base <= base[b0+12]; 
		5'h2: sel_base <= base[b0+13]; 
		5'h1: sel_base <= base[b0+14]; 
		5'h0: sel_base <= base[b0+15]; 
		default: sel_base <= base[b0-1]; 
	endcase
end

reg [7:0] cnt, cnt_lim;

reg signed [10:0] am_bresenham;
reg signed [ 9:0] pm_bresenham;

always @(*) begin : counter_limit
	case( lfo_freq[3:0] )
		4'hf: cnt_lim <= 8'd66;
		4'he: cnt_lim <= 8'd68;
		4'hd: cnt_lim <= 8'd70;
		4'hc: cnt_lim <= 8'd73;
		4'hb: cnt_lim <= 8'd76;
		4'ha: cnt_lim <= 8'd79;
		4'h9: cnt_lim <= 8'd82;
		4'h8: cnt_lim <= 8'd85;
		4'h7: cnt_lim <= 8'd89;
		4'h6: cnt_lim <= 8'd93;
		4'h5: cnt_lim <= 8'd98;
		4'h4: cnt_lim <= 8'd102;
		4'h3: cnt_lim <= 8'd108;
		4'h2: cnt_lim <= 8'd114;
		4'h1: cnt_lim <= 8'd120;
		4'h0: cnt_lim <= 8'd128;
	endcase
end

wire signed [7:0] pmd_min = (~{1'b0, lfo_pmd[6:0]})+8'b1;

reg lfo_clk, last_base, am_up, pm_up;

always @(posedge clk) begin : modulator
	if( rst || lfo_rst ) begin
		last_base	<= 1'd0;
		lfo_clk		<= 1'b0;
		cnt			<= 8'd0;
		am			<= 7'd0;
		pm			<= 8'd0;
		am_up		<= 1'b1;
		pm_up		<= 1'b1;
		am_bresenham <= 11'd0;
		pm_bresenham <= 10'd0;
	end
	else begin
		last_base <= sel_base;
		if( last_base != sel_base ) begin
			case( lfo_w )
			2'd0: begin // AM sawtooth
				if( am_bresenham > 0 ) begin
					if( am == lfo_amd ) begin
						am <= 7'd0;
						am_bresenham <= 11'd0;
					end
					else begin
						am <= am + 1'b1;
						am_bresenham <= am_bresenham 
						- { cnt_lim, 1'b0} + lfo_amd; 				
					end
				end
				else am_bresenham <= am_bresenham + lfo_amd;

				if( pm_bresenham > 0 ) begin
					if( pm == { 1'b0, lfo_pmd } ) begin
						pm <= pmd_min;
						pm_bresenham <= 10'd0;
					end
					else begin
						pm <= pm + 1'b1;
						pm_bresenham <= pm_bresenham 
						- cnt_lim + lfo_pmd;
					end
				end
				else pm_bresenham <= pm_bresenham + lfo_pmd;
				end
			2'd1: // AM square waveform
				if( cnt == cnt_lim ) begin
					cnt <= 8'd0;
					lfo_clk <= ~lfo_clk;
					am <= lfo_clk ? lfo_amd : 7'd0;
					pm <= lfo_clk ? {1'b0, lfo_pmd } : pmd_min;
				end
				else cnt <= cnt + 1'd1;			
			2'd2:  begin // AM triangle
				if( am_bresenham > 0 ) begin
					if( am == lfo_amd && am_up) begin
						am_up <= 1'b0;
						am_bresenham <= 11'd0;
					end
					else if( am == 8'd0 && !am_up) begin
						am_up <= 1'b1;
						am_bresenham <= 11'd0;
					end
					else begin
						am <= am_up ? am+1'b1 : am-1'b1;
						am_bresenham <= am_bresenham 
						- { cnt_lim, 1'b0} + lfo_amd; 				
					end
				end
				else am_bresenham <= am_bresenham + lfo_amd;
				
				if( pm_bresenham > 0 ) begin
					if( pm == {1'b0, lfo_pmd} && pm_up) begin
						pm_up <= 1'b0;
						pm_bresenham <= 10'd0;
					end
					else if( pm == pmd_min && !pm_up) begin
						pm_up <= 1'b1;
						pm_bresenham <= 10'd0;
					end
					else begin
						pm <= pm_up ? pm+1'b1 : pm-1'b1;
						pm_bresenham <= pm_bresenham 
						- cnt_lim + lfo_pmd;
					end
				end
				else pm_bresenham <= pm_bresenham + lfo_pmd;
				end
			2'd3: begin 
				casex( lfo_amd ) // same as real chip
					7'b1xxxxxx: am <= noise_am[6:0];
					7'b01xxxxx: am <= { 1'b0, noise_am[5:0] };
					7'b001xxxx: am <= { 2'b0, noise_am[4:0] };
					7'b0001xxx: am <= { 3'b0, noise_am[3:0] };
					7'b00001xx: am <= { 4'b0, noise_am[2:0] };
					7'b000001x: am <= { 5'b0, noise_am[1:0] };
					7'b0000001: am <= { 6'b0, noise_am[0]   };
					default:    am <= 7'd0;
				endcase
				casex( lfo_pmd ) 
					7'b1xxxxxx: pm <= noise_pm;
					7'b01xxxxx: pm <= { {2{noise_pm[7]}}, noise_pm[5:0] };
					7'b001xxxx: pm <= { {3{noise_pm[7]}}, noise_pm[4:0] };
					7'b0001xxx: pm <= { {4{noise_pm[7]}}, noise_pm[3:0] };
					7'b00001xx: pm <= { {5{noise_pm[7]}}, noise_pm[2:0] };
					7'b000001x: pm <= { {6{noise_pm[7]}}, noise_pm[1:0] };
					7'b0000001: pm <= { {7{noise_pm[7]}}, noise_pm[0]   };
					default:    pm <= 8'd0;
				endcase	
				end			
			endcase
		end
	end
end

genvar aux;
generate
	for( aux=0; aux<7; aux=aux+1 ) begin : amnoise
		jt51_lfo_lfsr #(.init(aux*aux+aux) ) u_noise_am(
			.rst( rst ),
			.clk( clk ),
			.base(sel_base),
			.out( noise_am[aux] )
		);
	end
	for( aux=0; aux<8; aux=aux+1 ) begin : pmnoise
		jt51_lfo_lfsr #(.init(4*aux*aux-3*aux+40) ) u_noise_pm(
			.rst( rst ),
			.clk( clk ),
			.base(sel_base),
			.out( noise_pm[aux] )
		);
	end
endgenerate
	
endmodule
