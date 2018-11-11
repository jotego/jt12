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
    Date: 14-2-2016
    


    YM2203 clone, based upon JT12 (YM2612) and JT49 (YM2149)

    
    */



module jt03 (
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, it not needed leave as 1'b1
    input   [7:0]   din,
    input   [1:0]   addr,
    input           cs_n,
    input           wr_n,
    input           limiter_en,
    
    output  [7:0]   dout,
    output          irq_n,
    // combined output
    output  signed  [11:0]  snd_right,
    output  signed  [11:0]  snd_left,
    output          snd_sample,
    // multiplexed output
    output signed   [8:0]   mux_right,  
    output signed   [8:0]   mux_left,
    output          mux_sample
);


jt12 u_fm(
    .rst        ( rst   ),        // rst should be at least 6 clk&cen cycles long
    .clk        ( clk   ),        // CPU clock
    .cen        ( cen   ),        // optional clock enable, it not needed leave as 1'b1
    .din        ( din   ),
    .addr       ( addr  ),
    .cs_n       ( cs_n  ),
    .wr_n       ( wr_n  ),
    .limiter_en ( limiter_en    ),    
    .dout       ( dout  ),
    .irq_n      ( irq_n ),
    .snd_right  ( snd_right ),
    .snd_left   ( snd_left  ),
    .snd_sample ( snd_sample),
    .mux_right  ( mux_right ),  
    .mux_left   ( mux_left  ),
    .mux_sample ( mux_sample)
);

wire [9:0] ssg_sound;

jt49 u_ssg( // note that input ports are not multiplexed
    .rst_n      ( ~rst  ),
    .clk        ( clk   ),    // signal on positive edge
    .cen        ( cen   ),    // clock enable on negative edge
    .addr       ( addr  ),
    .cs_n       ( cs_n  ),
    .wr_n       ( wr_n  ),  // write
    .din        ( din   ),
    .sound      ( sound ),
);


endmodule // jt03