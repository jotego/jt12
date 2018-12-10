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
    
    Each channel can use the full range of the DAC as they do not
    get summed in the real chip.

    Operator data is summed up without adding extra bits. This is
    the case of real YM3438, which was used on Megadrive 2 models.


*/

module jt12_interpol6(
    input               rst,
    input               clk,
    input               cen,    // system clock enable
    input               clk_en, // synthesizer clock enable = cen/6
    input  signed [11:0] snd_in,
    output signed [15:0] snd_out
);

localparam filterbw=17;
reg signed [filterbw-1:0] comb1,comb2, last_comb1, inter6, integ1, integ2;
reg signed [11:0] last;

// Comb filter at synthesizer sampling rate
always @(posedge clk) if(clk_en) begin
    last <= snd_in;
    comb1 <= {{(filterbw-12){snd_in[11]}},snd_in} - 
             {{(filterbw-12){last[11]}}  ,last  };
    last_comb1 <= comb1;
    comb2 <= comb1 - last_comb1;
end

// interpolator x6
always @(posedge clk) if(cen)
    inter6 <= clk_en ? comb2 : {filterbw{1'b0}};

// integrator at clk x cen sampling rate
always @(posedge clk) 
    if(rst) begin
        integ1 <= {filterbw{1'b0}};
        integ2 <= {filterbw{1'b0}};
    end else if(cen) begin
        integ1 <= integ1 + comb2;
        integ2 <= integ2 + integ1;
    end

assign snd_out = integ2[ filterbw-1:1 ];

endmodule // jt12_interpol6