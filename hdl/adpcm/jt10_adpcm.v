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

/*
static long stepsizeTable[ 16 ] =
{
57, 57, 57, 57, 77,102,128,153,
57, 57, 57, 57, 77,102,128,153
};

*/

// Sampling rates: 2kHz ~ 55.5 kHz. in 0.85Hz steps


module jt10_adpcm(
    input           rst_n,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [3:0]   data,
    output signed [15:0] pcm
);

parameter CHCNT = 6;

localparam stepw = 16;
localparam xw    = 15;

wire signed [xw-1:0] xn0_III;
reg signed [xw-1:0] dn, xn;
reg [14:0] step;
reg [7:0] step_val;

reg [3:0]  d0_II;   // new input data
reg [18:0] d_II;
reg [15:0] d_III;

reg [23:0] step2_II;
reg [stepw-1:0] step_III, step2_IV, step2_V;
reg signed [xw:0] xn_IV;
reg signed [xw-1:0] xn_V;
assign pcm = xn_V;

wire [16:0] step2b = step2[23:6];
reg dsign_II, dsign_III, dsign_IV;
wire [15:0] xn0_III;
wire [xw:0] xn0_sgnext_III = { xn0_III[xw-1], xn0_III };

always @(*) begin
    case (data[2:0])
        3'b0_??: step_val = 8'd57;
        3'b1_00: step_val = 8'd77;
        3'b1_01: step_val = 8'd102;
        3'b1_10: step_val = 8'd128;
        3'b1_11: step_val = 8'd153;
    endcase // data[2:0]
    d_II      = d0_II    * step_II; // 4 + 15 = 19 bits -> div by 8 -> 16 bits
    step2_III = step_lut * step_III; // 15 bits + 8 bits = 23 bits -> div 64 -> 17 bits
end

// Original pipeline: 6 stages, 6 channels take 36 clock cycles
// 8 MHz -> /12 divider -> 666 kHz
// 666 kHz -> 18.5 kHz

always @( posedge clk or negedge rst_n )
    if( ! rst_n ) begin
        xn <= 'd0;
    end else if(cen) begin
        // I
        d0_II     <= {data[2:0],1'b1};
        dsign_II  <= data[3];
        // II: step is first used here
        d_III     <= d_II[18:3]; // 16 bits
        dsign_III <= dsign_II;
        step_III  <= step_II;
        // III: old data first used here 
        xn_IV     <= dsign_III ? (xn0_sgnext_III-d_III) : (xn0_sgnext_III+d_III);
        dsign_IV  <= dsign_III;
        xsign_IV  <= xn0_III[xw-1];
        step2_IV  <= step2_III[23:6];
        // IV: limit outputs
        if( (xn_IV[xw] != xsign_IV) && ( xn_IV[xw] == dsign_IV ) )
            xn_V <= !xsign_IV ? 16'h8000 : 16'h7FFF;
        else
            xn_V <= xn_IV[xw-1:0];
        // step size for next data
        if( step2_IV < 17'd127 )
            step2_V  <= 17'd127;
        else if( step2_IV > 17'd24576 )
            step2_V  <= 17'd24576;
        else
            step2_V <= step2_IV;
        // V:
        xn_VI     <= Xn_V;
        step2_VI  <= step2_V;
        // VI:
        xn_VII    <= Xn_VI;
        step2_VII <= step2_VII;
    end

jt12_sh_rst #( .width(xw), .stages(CHCNT)) u_pcm_data(
    .clk    ( clk       ),
    .clk_en ( clk_en    ),
    .rst    ( ~rst_n    ),  
    .din    ( xn_V      ),
    .drop   ( xn0_III   )
);

jt12_sh_rst #( .width(stepw), .stages(CHCNT)) u_step_data(
    .clk    ( clk       ),
    .clk_en ( clk_en    ),
    .rst    ( ~rst_n    ),  
    .din    ( step2_V   ),
    .drop   ( step_II   )
);


endmodule // jt10_adpcm    