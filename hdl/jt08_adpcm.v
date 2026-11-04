/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */

module jt08_adpcm(
    input                 rst, clk, cen,
    input                 wr, rd, flag_reset,
    input          [3:0]  addr,
    input          [7:0]  din,
    output         [7:0]  dout,
    output         [3:0]  flags,
    output reg    [23:0]  mem_addr,
    output reg            mem_cs, mem_we,
    output reg     [7:0]  mem_din,
    input          [7:0]  mem_data,
    input                 mem_ok,
    output signed [15:0]  left, right
);
reg [7:0] regs[0:15];
reg [7:0] cpu_data, read_data;
reg clear_after_decode;
reg [15:0] phase, fifo;
reg [2:0] count;
reg [23:0] address;
reg latched, running, playing, eos, ready, drain, suppress;
reg [1:0] operation;
reg [7:0] divider;
reg dec_adv, dec_clear;
reg [3:0] dec_data, decode_wait;
reg signed [15:0] previous, current;
wire signed [15:0] decoded, interpolated, gained;
wire external_mem=regs[0][5];
wire recording=regs[0][6];
wire repeat_on=regs[0][4];
wire [4:0] address_shift=regs[1][1:0]!=0 ? 5'd5 : 5'd2;
wire [23:0] block_mask=(24'd1<<address_shift)-24'd1;
wire [23:0] start_address={8'd0,regs[3],regs[2]}<<address_shift;
wire at_end=(mem_addr & block_mask)==block_mask && (mem_addr>>address_shift)=={regs[5],regs[4]};
wire at_limit=(mem_addr & block_mask)==block_mask && (mem_addr>>address_shift)=={regs[13],regs[12]};
wire [16:0] next_phase={1'b0,phase}+{1'b0,regs[10],regs[9]};
wire base_cen=cen && divider==143;
wire signed [17:0] weight={1'b0,phase};
wire signed [33:0] mix_previous=$signed(previous)*(18'sd65536-weight);
wire signed [33:0] mix_current=$signed(current)*weight;
wire signed [33:0] mixed=mix_previous+mix_current;
integer i;

assign interpolated=mixed[31:16];
assign left=regs[1][7] ? gained>>>1 : 16'sd0;
assign right=regs[1][6] ? gained>>>1 : 16'sd0;
assign flags={playing,1'b0,ready,eos};
assign dout=external_mem && !recording && !regs[0][7] ? read_data : 8'd0;

always @(posedge clk) begin
    if(rst) begin
        for(i=0;i<16;i=i+1) regs[i]<=0;
        regs[12]<=8'hff;
        regs[13]<=8'hff;
        cpu_data<=0;
        read_data<=0;
        clear_after_decode<=0;
        phase<=0;
        fifo<=0;
        count<=0;
        address<=0;
        latched<=0;
        running<=0;
        playing<=0;
        eos<=0;
        ready<=1;
        drain<=0;
        suppress<=0;
        operation<=0;
        mem_addr<=0;
        mem_cs<=0;
        mem_we<=0;
        mem_din<=0;
        divider<=0;
        dec_adv<=0;
        dec_clear<=1;
        dec_data<=0;
        decode_wait<=0;
        previous<=0;
        current<=0;
    end else begin
        if(flag_reset) begin
            eos<=0;
            playing<=0;
        end
        if(cen) begin
            divider<=divider==143 ? 8'd0 : divider+8'd1;
            dec_adv<=0;
            dec_clear<=0;
            if(dec_adv) decode_wait<=7;
            else if(decode_wait!=0) begin
                decode_wait<=decode_wait-4'd1;
                if(decode_wait==1) begin
                    current<=decoded;
                    if(clear_after_decode) begin
                        dec_clear<=1;
                        clear_after_decode<=0;
                    end
                end
            end
        end
        if(base_cen) begin
            if(!regs[0][7] || recording || !running) begin
                phase<=0;
                previous<=current;
            end else begin
                phase<=next_phase[15:0];
                if(next_phase[16]) begin
                    if(count!=0) begin
                        dec_data<=fifo>>((count-1)*4);
                        dec_adv<=1;
                        previous<=current;
                        count<=count-3'd1;
                        if((drain || !external_mem) && count==1) begin
                            eos<=1;
                            drain<=0;
                            if(repeat_on && external_mem) clear_after_decode<=1;
                            else running<=0;
                        end
                    end
                    if(count<4 && (!drain || (repeat_on && count==1)) && !mem_cs && (external_mem || count!=1)) begin
                        if(external_mem) begin
                            mem_addr<=latched ? address : start_address;
                            mem_we<=0;
                            mem_cs<=1;
                            operation<=0;
                            latched<=1;
                        end else begin
                            if(!ready) begin
                                fifo<=(fifo<<8)|cpu_data;
                                count<=count+3'd2-(count!=0 ? 3'd1 : 3'd0);
                            end
                            ready<=1;
                        end
                    end
                end
            end
        end
        if(mem_cs && mem_ok) begin
            mem_cs<=0;
            address<=at_limit && !at_end ? 24'd0 : mem_addr+24'd1;
            if(operation==0) begin
                fifo<=(fifo<<8)|mem_data;
                cpu_data<=mem_data;
                if(at_end) begin
                    count<=1;
                    drain<=1;
                    if(repeat_on) address<=start_address;
                end else count<=count+3'd2;
            end else if(operation==1) begin
                fifo<=(fifo<<8)|mem_data;
                cpu_data<=mem_data;
                count<=count+3'd2;
                if(at_end) drain<=1;
                ready<=1;
            end else begin
                ready<=1;
                if(at_end) begin
                    eos<=1;
                    latched<=0;
                    suppress<=repeat_on;
                end
            end
        end
        if((rd || (wr && addr==8)) && addr==8 && !regs[0][7] && external_mem && !recording && !mem_cs) begin
            read_data<=!latched ? cpu_data : count>=2 ? fifo>>((count-2)*4) : 8'd0;
            count<=!latched ? 3'd2 : count>=2 ? count-3'd2 : 3'd0;
            fifo<=!latched ? {8'd0,cpu_data} : fifo;
            if(drain && latched) begin
                if(count<=2) begin
                    eos<=1;
                    drain<=0;
                    latched<=0;
                end
            end else begin
                mem_addr<=latched ? address : start_address;
                mem_we<=0;
                mem_cs<=1;
                operation<=1;
                latched<=1;
            end
        end
        if(wr) begin
            regs[addr]<=din;
            if(addr==8) begin
                cpu_data<=din;
                if(regs[0][7] && !recording && !external_mem) ready<=0;
                if(!regs[0][7] && recording && external_mem && !mem_cs && !suppress) begin
                    mem_addr<=latched ? address : start_address;
                    mem_din<=din;
                    mem_we<=1;
                    mem_cs<=1;
                    operation<=2;
                    latched<=1;
                    ready<=0;
                end
            end
            if(addr==0) begin
                mem_cs<=0;
                if(din[0]) begin
                    if(running) eos<=1;
                    running<=0;
                    ready<=1;
                end else begin
                    latched<=0;
                    drain<=0;
                    suppress<=0;
                    playing<=din[7];
                    running<=din[7];
                    ready<=1;
                    if(din[7]) begin
                        eos<=0;
                        count<=0;
                        fifo<=0;
                        phase<=0;
                        current<=0;
                        dec_clear<=1;
                    end
                end
            end
        end
    end
end

jt10_adpcmb #(
    .OPNA  ( 1         )
) u_decoder(
    .rst_n ( ~rst      ),
    .clk   ( clk       ),
    .cen   ( cen       ),
    .data  ( dec_data  ),
    .chon  ( 1'b1      ),
    .adv   ( dec_adv   ),
    .clr   ( dec_clear ),
    .pcm   ( decoded   )
);

jt10_adpcmb_gain u_gain(
    .rst_n   ( ~rst         ),
    .clk     ( clk          ),
    .cen55   ( base_cen     ),
    .tl      ( regs[11]     ),
    .pcm_in  ( interpolated ),
    .pcm_out ( gained       )
);

endmodule
