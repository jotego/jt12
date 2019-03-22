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

// Apply linear interpolation to rise
// sampling frequency from 18.5 kHz to 55.5 kHz

module jt10_adpcm_interpol(
    input           rst_n,
    input           clk,        // CPU clock
    input           cen,        //  55 kHz
    input   [2:0]   ch,
    input      signed [17:0] pcm_in,    // 18.5 kHz
    input      signed [17:0] step,      // 18.5 kHz
    output reg signed [15:0] pcm_out    // 55.5 kHz
);
