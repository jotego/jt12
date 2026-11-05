/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */
module jt08_mixer(
    input rst, clk,
    input signed [15:0] adpcm,
    input signed [17:0] fm,
    input signed [18:0] rhythm,
    output reg signed [15:0] snd
);
reg signed [18:0] fm_adpcm, rhythm_d;
reg signed [20:0] total;

always @(posedge clk) begin
    if(rst) begin
        fm_adpcm<=0;
        rhythm_d<=0;
        total<=0;
        snd<=0;
    end else begin
        fm_adpcm<=$signed({fm[17],fm})+$signed({{3{adpcm[15]}},adpcm});
        rhythm_d<=rhythm;
        total<=$signed({{2{fm_adpcm[18]}},fm_adpcm})+$signed({{2{rhythm_d[18]}},rhythm_d});
        snd<=total>32767 ? 16'sh7fff : total< -32768 ? 16'sh8000 : total[15:0];
    end
end
endmodule
