/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */
module jt08_mixer(
    input signed [15:0] adpcm,
    input signed [17:0] fm,
    input signed [18:0] rhythm,
    output signed [15:0] snd
);
wire signed [20:0] total={{3{fm[17]}},fm}+{{2{rhythm[18]}},rhythm}+{{5{adpcm[15]}},adpcm};
assign snd=total>32767 ? 16'sh7fff : total< -32768 ? 16'sh8000 : total[15:0];
endmodule
