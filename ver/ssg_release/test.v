`timescale 1ns/1ps
module test;
reg clk=0, rst=1, keyon=0;
wire [9:0] eg;
always #5 clk=~clk;

jt12_eg #(.num_ch(3)) uut(
    .rst ( rst ), .clk ( clk ), .clk_en ( 1'b1 ),
    .zero ( 1'b0 ), .eg_stop ( 1'b0 ),
    .keycode_II ( 5'd0 ), .arate_I ( 5'd0 ),
    .rate1_I ( 5'd0 ), .rate2_I ( 5'd0 ),
    .rrate_I ( 4'd0 ), .sl_I ( 4'd0 ), .ks_II ( 2'd0 ),
    .ssg_en_I ( 1'b1 ), .ssg_eg_I ( 3'b100 ),
    .keyon_I ( keyon ), .csm_key_I ( 1'b0 ),
    .csm_mode ( 1'b0 ), .cur_ch ( 3'd0 ),
    .lfo_mod ( 7'd0 ), .amsen_IV ( 1'b0 ),
    .ams_IV ( 2'd0 ), .tl_IV ( 7'd0 ),
    .eg_V ( eg ), .pg_rst_II ( )
);

jt12_eg #(.num_ch(6)) uut_six(
    .rst ( rst ), .clk ( clk ), .clk_en ( 1'b1 ),
    .zero ( 1'b0 ), .eg_stop ( 1'b0 ),
    .keycode_II ( 5'd0 ), .arate_I ( 5'd0 ),
    .rate1_I ( 5'd0 ), .rate2_I ( 5'd0 ),
    .rrate_I ( 4'd0 ), .sl_I ( 4'd0 ), .ks_II ( 2'd0 ),
    .ssg_en_I ( 1'b1 ), .ssg_eg_I ( 3'b100 ),
    .keyon_I ( keyon ), .csm_key_I ( 1'b0 ),
    .csm_mode ( 1'b0 ), .cur_ch ( 3'd0 ),
    .lfo_mod ( 7'd0 ), .amsen_IV ( 1'b0 ),
    .ams_IV ( 2'd0 ), .tl_IV ( 7'd0 ),
    .eg_V ( ), .pg_rst_II ( )
);

initial begin
    repeat(3) @(negedge clk);
    rst=0;
    keyon=1;
    repeat(28) @(negedge clk);
    force uut.eg_in_I = 10'h080;
    force uut.ssg_inv_in_I = 1'b1;
    force uut_six.eg_in_I = 10'h080;
    force uut_six.ssg_inv_in_I = 1'b1;
    keyon=0;
    #1;
    if (uut.eg_release_I!==10'h180 || uut.ssg_inv_out_I!==1'b0 ||
        uut_six.eg_release_I!==10'h180 || uut_six.ssg_inv_out_I!==1'b0)
        begin $display("FAIL inverted release start"); $finish; end
    @(posedge clk); #1;
    if (uut.eg_in_II!==10'h180 || uut_six.eg_in_II!==10'h180)
        begin $display("FAIL inverted release pipeline"); $finish; end
    @(negedge clk);
    release uut.ssg_inv_in_I;
    force uut.ssg_inv_in_I = 1'b0;
    release uut_six.ssg_inv_in_I;
    force uut_six.ssg_inv_in_I = 1'b0;
    keyon=1;
    repeat(28) @(negedge clk);
    keyon=0;
    #1;
    if (uut.eg_release_I!==10'h080 || uut_six.eg_release_I!==10'h080)
        begin $display("FAIL plain release start"); $finish; end
    $display("PASS"); $finish;
end
endmodule
