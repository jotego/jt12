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

// Sampling rates: 2kHz ~ 55.5 kHz. in 0.85Hz steps

module jt10_adpcm(
    input           rst_n,
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [3:0]   data,
    output signed [15:0] pcm
);

localparam stepw = 15;
localparam xw    = 16;

reg signed [xw-1:0] x1, x2, x3, x5, x6;
reg signed [xw:0] x4;
reg [stepw-1:0] step1, step2, step5, step6;
reg [stepw+1:0] step3, step4;
assign pcm = x6;

reg  [18:0] d2l;
reg  [15:0] d3;
wire [xw:0] x3_sgnext = { x3[xw-1], x3 };
reg  [3:0]  d2;
reg         sign2, sign3, sign4, x3sign;
reg  [7:0]  step_val;
reg  [22:0] step2l;

always @(*) begin
    casez( d2[3:1] )
        3'b0_??: step_val = 8'd57;
        3'b1_00: step_val = 8'd77;
        3'b1_01: step_val = 8'd102;
        3'b1_10: step_val = 8'd128;
        3'b1_11: step_val = 8'd153;
    endcase // data[2:0]
    d2l    = d2 * step2; // 4 + 15 = 19 bits -> div by 8 -> 16 bits
    step2l = step_val * step2; // 15 bits + 8 bits = 23 bits -> div 64 -> 17 bits
end

// Original pipeline: 6 stages, 6 channels take 36 clock cycles
// 8 MHz -> /12 divider -> 666 kHz
// 666 kHz -> 18.5 kHz = 55.5/3 kHz

always @( posedge clk or negedge rst_n )
    if( ! rst_n ) begin
        x1 <= 'd0; step1 <= 'd0; 
        x2 <= 'd0; step2 <= 'd0;
        x3 <= 'd0; step3 <= 'd0;
        x4 <= 'd0; step4 <= 'd0;
        x5 <= 'd0; step5 <= 'd0;
        x6 <= 'd0; step6 <= 'd0;
        d2 <= 'd0; d3 <= 'd0;
        sign2 <= 'b0;
        sign3 <= 'b0; x3sign <= 'b0;
        sign4 <= 'b0;
    end else if(cen) begin
        // I
        d2        <= {data[2:0],1'b1};
        sign2     <= data[3];
        x2        <= x1;
        step2     <= step1;
        // II multiply and obtain the offset
        d3        <= d2l[18:3]; // 16 bits
        sign3     <= sign2;
        x3        <= x2;
        step3     <= step2l[22:6];
        // III
        x4        <= sign3 ? (x3_sgnext-{1'b0,d3}) : (x3_sgnext+{1'b0,d3});
        sign4     <= sign3;
        x3sign    <= x3[xw-1];
        step4     <= step3;
        // IV: limit outputs
        if( (x4[xw] != x3sign) && ( x4[xw] == sign4 ) )
            x5 <= !x3sign ? 16'h8000 : 16'h7FFF;
        else
            x5 <= x4[xw-1:0];

        if( step4 < 17'd127 )
            step5  <= 15'd127;
        else if( step4 > 17'd24576 )
            step5  <= 15'd24576;
        else
            step5 <= step4[15:0];
        // V: pad one cycle
        x6     <= x5;
        step6  <= step5;
        // VI: close the loop
        x1    <= x6;
        step1 <= step6;
    end


endmodule // jt10_adpcm    