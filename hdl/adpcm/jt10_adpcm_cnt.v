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
    Date: 21-03-2019
*/

module jt10_adpcm_cnt(
    input           rst_n,
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [11:0]  addr_in,
    input   [ 2:0]  ch,
    input           we_start,
    input           we_end,
    output          aon,
    output          aoff,
    output  reg [19:0]  cnt,
    output          sel
);

parameter CHID = 0; // channel ID

reg on;
wire done = cnt[19:8] == addr_end;
reg [11:0] addr_start, addr_end;

wire this_ch = CHID == ch;

always @(posedge clk or negedge rst_n) 
    if( !rst_n ) begin
        addr_start <= 'd0;
        addr_end   <= 'd0;
    end else if( cen ) begin
        addr_start <= this_ch & we_start ? addr_in;
        addr_end   <= this_ch & we_end   ? addr_in;
    end

always @(posedge clk or negedge rst_n) 
    if( !rst_n ) begin
        cnt <= 20'd0;
    end else if( cen ) begin
        if( aon && !on ) begin
            on <= 1'b1;
            cnt <= { addr_start, 8'd0 };
            sel <= 1'b0;
        end
        if( aoff ) on <= 1'b0;
        if( on && !done ) begin
            {cnt, sel} <= {cnt, sel} + 21'd1;
        end
    end


endmodule // jt10_adpcm_cnt
