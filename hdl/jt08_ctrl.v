/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */

module jt08_ctrl(
    input             rst, clk, write,
    input      [1:0]  addr,
    input      [7:0]  din,
    input             busy,
    input      [1:0]  timer_flags,
    input      [3:0]  adpcm_flags,
    input      [7:0]  psg_dout, adpcm_dout,
    output            six_ch,
    output reg        clear_flags,
    output            irq_n,
    output reg [7:0]  dout
);

reg [8:0] selected;
reg [7:0] irq_enable;
reg [4:0] flag_mask;
wire [4:0] flags = {adpcm_flags[2:0],timer_flags} & ~flag_mask;

assign six_ch = irq_enable[7];
assign irq_n = ~|(flags & irq_enable[4:0]);

always @(posedge clk) begin
    if(rst) begin
        selected <= 0;
        irq_enable <= 8'h1f;
        flag_mask <= 5'h1c;
        clear_flags <= 0;
    end else begin
        clear_flags <= 0;
        if(write) begin
            if(!addr[0]) selected <= {addr[1],din};
            else if(addr[1]==selected[8]) begin
                case(selected)
                    9'h029: irq_enable <= din;
                    9'h110: begin
                        if(din[7]) clear_flags <= 1;
                        else flag_mask <= din[4:0];
                    end
                    default:;
                endcase
            end
        end
    end
end

always @* begin
    case(addr)
        2'd0: dout = {busy,5'd0,timer_flags};
        2'd1: dout = selected<9'h010 ? psg_dout : selected==9'h0ff ? 8'd1 : 8'd0;
        2'd2: dout = {busy,1'b0,adpcm_flags[3],flags};
        default: dout = selected[7:0]==8 ? adpcm_dout : 8'd0;
    endcase
end

endmodule
