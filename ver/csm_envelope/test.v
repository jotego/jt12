`timescale 1ns/1ps
module test;
reg clk=0, rst=1, csm_mode=0, csm_key_I=0;
reg [2:0] cur_ch=0;
wire [9:0] eg_V;
wire pg_rst_II;
always #5 clk=~clk;

jt12_eg #(.num_ch(3)) uut(
    .rst ( rst ), .clk ( clk ), .clk_en ( 1'b1 ),
    .zero ( 1'b0 ), .eg_stop ( 1'b0 ),
    .keycode_II ( 5'd0 ), .arate_I ( 5'd0 ),
    .rate1_I ( 5'd0 ), .rate2_I ( 5'd0 ),
    .rrate_I ( 4'd0 ), .sl_I ( 4'd0 ), .ks_II ( 2'd0 ),
    .ssg_en_I ( 1'b0 ), .ssg_eg_I ( 3'd0 ),
    .keyon_I ( 1'b0 ), .csm_key_I ( csm_key_I ),
    .csm_mode ( csm_mode ), .cur_ch ( cur_ch ),
    .lfo_mod ( 7'd0 ), .amsen_IV ( 1'b0 ),
    .ams_IV ( 2'd0 ), .tl_IV ( 7'd40 ),
    .eg_V ( eg_V ), .pg_rst_II ( pg_rst_II )
);

initial begin
    $dumpfile("test.lxt"); $dumpvars;
    // Isolate the CSM path from the envelope rate generator.
    force uut.eg_pure_IV = 10'd0;
    repeat(3) @(negedge clk);
    rst=0; cur_ch=2;
    repeat(4) @(negedge clk);
    if(eg_V!==10'd320) begin $display("FAIL normal TL: %0d",eg_V); $finish; end
    csm_mode=1;
    repeat(2) @(negedge clk);
    if(eg_V!==10'd0) begin $display("FAIL CSM TL bypass: %0d",eg_V); $finish; end
    csm_key_I=1;
    @(negedge clk); csm_key_I=0;
    repeat(2) @(negedge clk);
    if(uut.eg_feedback_IV!==10'd320 || eg_V!==10'd0)
        begin $display("FAIL CSM TL preload"); $finish; end
    @(negedge clk);
    if(uut.eg_feedback_IV!==10'd0 || eg_V!==10'd0)
        begin $display("FAIL CSM preload pulse"); $finish; end
    repeat(8) @(negedge clk);
    if(uut.eg_in_I!==10'd320) begin $display("FAIL CSM feedback delay"); $finish; end
    cur_ch=0;
    repeat(5) @(negedge clk);
    if(eg_V!==10'd320) begin $display("FAIL other channel TL: %0d",eg_V); $finish; end
    $display("PASS"); $finish;
end
endmodule
