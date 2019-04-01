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

// Gain is assumed to be 0.75dB per bit.

module jt10_adpcmb_gain(
    input                    rst_n,
    input                    clk,        // CPU clock
    input                    cen55,
    input             [ 7:0] tl,         // ADPCM Total Level
    input      signed [15:0] pcm_in,
    output reg signed [15:0] pcm_out
);

reg [9:0] lin_gain;

always @(posedge clk or negedge rst_n) begin
    if( !rst_n)
        lin_gain <= 'd0;
    else begin
        case( ~tl[2:0] )
            3'd0: lin_gain <= 10'd512;
            3'd1: lin_gain <= 10'd470;
            3'd2: lin_gain <= 10'd431;
            3'd3: lin_gain <= 10'd395;
            3'd4: lin_gain <= 10'd362;
            3'd5: lin_gain <= 10'd332;
            3'd6: lin_gain <= 10'd305;
            3'd7: lin_gain <= 10'd280;
        endcase
    end
end

reg signed [15:0] pcm_sh;
reg signed [31:0] pcm_mul;
reg toggle;

wire signed [15:0] lins = {6'b0,lin_gain};

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        toggle <= 'b0;
    end else if(cen55) begin
        pcm_mul <= lins * pcm_in;
        pcm_out <= pcm_sh;
        toggle  <= ~toggle;
    end

reg toggle_last;
reg [4:0] shift;

always @(posedge clk or negedge rst_n)
    if( !rst_n ) begin
        shift  <= 'd0;
        pcm_sh <= 'd0;
    end else begin
        toggle_last <= toggle;
        if( toggle != toggle_last) begin
            pcm_sh <= pcm_mul[24:9];
            shift  <= ~tl[7:3];
        end
        if( shift != 5'd0 ) begin
            pcm_sh <= pcm_sh>>>1;
            shift  <= shift-5'd1;
        end
    end

endmodule // jt10_adpcm_gain
