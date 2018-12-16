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
    Date: 10-12-2018
    
*/

module jt12_interpol #(parameter calcw=18, inw=16, cntw=4, rate=2)(
    input               rst,
    input               clk,
(* direct_enable *)    input               cen_in,
(* direct_enable *)    input               cen_out,
    input  signed [inw-1:0] snd_in,
    output reg signed [inw-1:0] snd_out
);

reg signed [calcw-1:0] comb1,comb2, last_comb1, inter6, integ1, integ2;
reg signed [inw-1:0] last;
localparam wdiff = calcw - inw;

// Comb filter at synthesizer sampling rate
always @(posedge clk)
    if(rst) begin
        comb1 <= {calcw{1'b0}};
        comb2 <= {calcw{1'b0}};
        last_comb1 <= {calcw{1'b0}};
        last <= {inw{1'b0}};
    end else if(cen_in) begin
        last <= snd_in;
        comb1 <= {{wdiff{snd_in[inw-1]}},snd_in} - 
                 {{wdiff{last[inw-1]}}  ,last  };
        last_comb1 <= comb1;
        comb2 <= comb1 - last_comb1;
    end

reg [cntw-1:0] inter_cnt;

// interpolator 
always @(posedge clk) 
    if(rst) begin
        inter6 <= {calcw{1'b0}};
        inter_cnt <= {cntw{1'b0}};
    end else if(cen_out) begin
        inter6 <= inter_cnt=={cntw{1'b0}} ? comb2 : {calcw{1'b0}};
        /* verilator lint_off WIDTH */
        inter_cnt <= inter_cnt==rate-1'b1 ? {cntw{1'b0}} : inter_cnt+1'b1;
        /* verilator lint_on WIDTH */
    end

// integrator at clk x cen sampling rate
always @(posedge clk) 
    if(rst) begin
        integ1 <= {calcw{1'b0}};
        integ2 <= {calcw{1'b0}};
        snd_out <= {inw{1'b0}};
    end else if(cen_out) begin
        integ1 <= integ1 + inter6;
        integ2 <= integ2 + integ1;
        snd_out<= integ2[calcw-1:wdiff];
    end

//assign snd_out = integ2[ calcw-1:0 ];


endmodule // jt12_interpol6