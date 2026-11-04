/* SPDX-FileCopyrightText: 2026 Andrea Bogazzi
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 04-11-2026 */

module jt08(
    input                rst, clk, cen,
    input        [7:0]   din,
    input        [1:0]   addr,
    input                cs_n, wr_n, rd_n,
    output       [7:0]   dout,
    output               irq_n,
    input        [7:0]   IOA_in, IOB_in,
    output       [7:0]   IOA_out, IOB_out,
    output               IOA_oe, IOB_oe,
    output       [7:0]   psg_A, psg_B, psg_C,
    output       [9:0]   psg_snd,
    output signed [15:0] fm_left, fm_right,
    output        [12:0] rhythm_addr,
    output               rhythm_cs,
    input         [7:0]  rhythm_data,
    output signed [18:0] rhythm_left, rhythm_right,
    output        [23:0] adpcm_addr,
    output               adpcm_cs, adpcm_we,
    output        [7:0]  adpcm_din,
    input         [7:0]  adpcm_data,
    input                adpcm_ok,
    output signed [15:0] adpcm_left, adpcm_right,
    output signed [15:0] snd_left, snd_right,
    output reg           snd_sample
);

wire [7:0] core_dout;
wire signed [17:0] fm_full_left, fm_full_right;
wire raw_sample;
wire flag_reset;
wire [3:0] adpcm_flags;
wire [7:0] adpcm_dout;
reg read_l;
wire read_bus=!cs_n && !rd_n;
wire read_pulse=read_bus && !read_l;
reg [8:0] selected;
reg write_l;
wire write_bus=!cs_n && !wr_n;
wire write_pulse=write_bus && !write_l;
wire data_write=write_pulse && addr[0] && addr[1]==selected[8];
always @(posedge clk) begin
    write_l<=write_bus;
    read_l<=read_bus;
    if(rst) begin
        write_l<=0;
        read_l<=0;
        selected<=0;
    end else if(write_pulse && !addr[0]) selected<={addr[1],din};
end

jt08_rhythm u_rhythm(
    .rst      ( rst                                   ),
    .clk      ( clk                                   ),
    .cen      ( cen                                   ),
    .wr       ( data_write && selected[8:4]==5'b00001 ),
    .addr     ( selected[3:0]                         ),
    .din      ( din                                   ),
    .rom_addr ( rhythm_addr                           ),
    .rom_cs   ( rhythm_cs                             ),
    .rom_data ( rhythm_data                           ),
    .left     ( rhythm_left                           ),
    .right    ( rhythm_right                          )
);
jt08_adpcm u_adpcm(
    .rst        ( rst                                           ),
    .clk        ( clk                                           ),
    .cen        ( cen                                           ),
    .wr         ( data_write && selected[8] && selected[7:4]==0 ),
    .rd         ( read_pulse && addr==3 && selected[7:0]==8     ),
    .flag_reset ( flag_reset                                    ),
    .addr       ( selected[3:0]                                 ),
    .din        ( din                                           ),
    .dout       ( adpcm_dout                                    ),
    .flags      ( adpcm_flags                                   ),
    .mem_addr   ( adpcm_addr                                    ),
    .mem_cs     ( adpcm_cs                                      ),
    .mem_we     ( adpcm_we                                      ),
    .mem_din    ( adpcm_din                                     ),
    .mem_data   ( adpcm_data                                    ),
    .mem_ok     ( adpcm_ok                                      ),
    .left       ( adpcm_left                                    ),
    .right      ( adpcm_right                                   )
);

jt08_mixer u_mix_left(
    .fm     ( fm_full_left ),
    .rhythm ( rhythm_left  ),
    .adpcm  ( adpcm_left   ),
    .snd    ( snd_left     )
);
jt08_mixer u_mix_right(
    .fm     ( fm_full_right ),
    .rhythm ( rhythm_right  ),
    .adpcm  ( adpcm_right   ),
    .snd    ( snd_right     )
);

reg sample_l;
assign dout = !cs_n && !rd_n ? core_dout : 8'hff;

always @(posedge clk) begin
    if(rst) begin
        sample_l <= 0;
        snd_sample <= 0;
    end else begin
        sample_l <= raw_sample;
        snd_sample <= raw_sample && !sample_l;
    end
end

jt12_top #(
    .use_lfo          ( 1             ),
    .use_ssg          ( 1             ),
    .num_ch           ( 6             ),
    .use_pcm          ( 0             ),
    .use_adpcm        ( 0             ),
    .OPNA             ( 1             ),
    .JT49_DIV         ( 3             ),
    .mask_div         ( 0             )
) u_core(
    .opna_adpcm_flags ( adpcm_flags   ),
    .opna_adpcm_data  ( adpcm_dout    ),
    .opna_flag_reset  ( flag_reset    ),
    .rst              ( rst           ),
    .clk              ( clk           ),
    .cen              ( cen           ),
    .din              ( din           ),
    .addr             ( addr          ),
    .cs_n             ( cs_n          ),
    .wr_n             ( wr_n          ),
    .dout             ( core_dout     ),
    .irq_n            ( irq_n         ),
    .en_hifi_pcm      ( 1'b0          ),
    .adpcma_addr      (               ),
    .adpcma_bank      (               ),
    .adpcma_roe_n     (               ),
    .adpcma_data      ( 8'd0          ),
    .adpcmb_addr      (               ),
    .adpcmb_data      ( 8'd0          ),
    .adpcmb_roe_n     (               ),
    .IOA_in           ( IOA_in        ),
    .IOB_in           ( IOB_in        ),
    .IOA_out          ( IOA_out       ),
    .IOB_out          ( IOB_out       ),
    .IOA_oe           ( IOA_oe        ),
    .IOB_oe           ( IOB_oe        ),
    .psg_A            ( psg_A         ),
    .psg_B            ( psg_B         ),
    .psg_C            ( psg_C         ),
    .fm_full_left     ( fm_full_left  ),
    .fm_full_right    ( fm_full_right ),
    .fm_snd_left      ( fm_left       ),
    .fm_snd_right     ( fm_right      ),
    .adpcmA_l         (               ),
    .adpcmA_r         (               ),
    .adpcmB_l         (               ),
    .adpcmB_r         (               ),
    .psg_snd          ( psg_snd       ),
    .snd_right        (               ),
    .snd_left         (               ),
    .snd_sample       ( raw_sample    ),
    .ch_enable        ( 6'h3f         ),
    .debug_bus        ( 8'd0          ),
    .debug_view       (               )
);

endmodule
