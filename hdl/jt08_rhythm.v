/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */

module jt08_rhythm(
    input                 rst, clk, cen,
    input                 wr,
    input          [3:0]  addr,
    input          [7:0]  din,
    output         [12:0] rom_addr,
    output                rom_cs,
    input          [7:0]  rom_data,
    output signed  [18:0] left, right
);
reg [2:0] voice;
reg [8:0] divider;
reg half_rate;
reg [5:0] active, clear;
reg [14:0] position[0:5];
reg [7:0] level[0:5];
reg [5:0] total;
reg signed [15:0] sample[0:5];
wire advance = divider<9'd6 && (voice<4 || half_rate);
wire running = active[voice];
wire [3:0] nibble = position[voice][0] ? rom_data[3:0] : rom_data[7:4];
wire signed [15:0] decoded;
wire [6:0] attenuation = {2'd0,~level[voice][4:0]} + {1'd0,~total};
wire signed [31:0] expanded = $signed(decoded) * 32'sd16;
wire signed [31:0] scaled = (expanded * $signed({1'b0,4'd15-{1'b0,attenuation[2:0]}})) >>> (5+attenuation[6:3]);
integer i, pair;
genvar channel;
wire signed [15:0] lane_l[0:5], lane_r[0:5];
reg signed [16:0] pair_l[0:2], pair_r[0:2];
reg signed [17:0] quad_l, quad_r, tail_l, tail_r;
reg signed [18:0] sum_l, sum_r;

function [14:0] start_address;
    input [2:0] channel;
    begin
        case(channel)
            0: start_address=15'h0000;
            1: start_address=15'h0380;
            2: start_address=15'h0880;
            3: start_address=15'h3700;
            4: start_address=15'h3a00;
            default: start_address=15'h3f00;
        endcase
    end
endfunction
function [14:0] stop_address;
    input [2:0] channel;
    begin
        case(channel)
            0: stop_address=15'h0380;
            1: stop_address=15'h0880;
            2: stop_address=15'h3700;
            3: stop_address=15'h3a00;
            4: stop_address=15'h3f00;
            default: stop_address=15'h4000;
        endcase
    end
endfunction

assign rom_addr = position[voice][13:1];
assign rom_cs = advance && running && !clear[voice] && !position[voice][0] && position[voice]!=stop_address(voice);
assign left = sum_l;
assign right = sum_r;

generate
    for(channel=0;channel<6;channel=channel+1) begin: gen_mix_lane
        assign lane_l[channel]=active[channel] && level[channel][7] ? sample[channel] : 16'sd0;
        assign lane_r[channel]=active[channel] && level[channel][6] ? sample[channel] : 16'sd0;
    end
endgenerate

always @(posedge clk) begin
    if(rst) begin
        for(pair=0;pair<3;pair=pair+1) begin
            pair_l[pair]<=0;
            pair_r[pair]<=0;
        end
        quad_l<=0;
        quad_r<=0;
        tail_l<=0;
        tail_r<=0;
        sum_l<=0;
        sum_r<=0;
    end else begin
        for(pair=0;pair<3;pair=pair+1) begin
            pair_l[pair]<=$signed({lane_l[2*pair][15],lane_l[2*pair]})+$signed({lane_l[2*pair+1][15],lane_l[2*pair+1]});
            pair_r[pair]<=$signed({lane_r[2*pair][15],lane_r[2*pair]})+$signed({lane_r[2*pair+1][15],lane_r[2*pair+1]});
        end
        quad_l<=$signed({pair_l[0][16],pair_l[0]})+$signed({pair_l[1][16],pair_l[1]});
        quad_r<=$signed({pair_r[0][16],pair_r[0]})+$signed({pair_r[1][16],pair_r[1]});
        tail_l<={pair_l[2][16],pair_l[2]};
        tail_r<={pair_r[2][16],pair_r[2]};
        sum_l<=$signed({quad_l[17],quad_l})+$signed({tail_l[17],tail_l});
        sum_r<=$signed({quad_r[17],quad_r})+$signed({tail_r[17],tail_r});
    end
end

always @(posedge clk) begin
    if(rst) begin
        voice<=0;
        divider<=144;
        half_rate<=1;
        active<=0;
        clear<=0;
        total<=0;
        for(i=0;i<6;i=i+1) begin
            position[i]<=start_address(i[2:0]);
            level[i]<=0;
            sample[i]<=0;
        end
    end else begin
        if(cen) begin
            voice<=voice==5 ? 3'd0 : voice+3'd1;
            divider<=divider==431 ? 9'd0 : divider+9'd1;
            if(divider==431) half_rate<=~half_rate;
            clear[voice]<=0;
            sample[voice]<=attenuation>=63 ? 16'sd0 : {scaled[15:2],2'b0};
            if(advance && running && !clear[voice]) begin
                if(position[voice]==stop_address(voice)) active[voice]<=0;
                else position[voice]<=position[voice]+15'd1;
            end
        end
        if(wr) begin
            if(addr==1) total<=din[5:0];
            if(addr>=8 && addr<=13) level[addr-8]<=din;
            if(addr==0) begin
                for(i=0;i<6;i=i+1) if(din[i]) begin
                    active[i]<=!din[7];
                    clear[i]<=1;
                    position[i]<=start_address(i[2:0]);
                    sample[i]<=0;
                end
            end
        end
    end
end

jt10_adpcm u_decoder(
    .rst_n ( ~rst                                                                       ),
    .clk   ( clk                                                                        ),
    .cen   ( cen                                                                        ),
    .data  ( nibble                                                                     ),
    .chon  ( advance && running && !clear[voice] && position[voice]!=stop_address(voice)  ),
    .clr   ( clear[voice]                                                               ),
    .pcm   ( decoded                                                                    )
);

endmodule
