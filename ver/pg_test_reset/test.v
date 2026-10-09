`timescale 1ns/1ps
module test;
reg clk=0, rst=1, pg_stop=0;
wire [9:0] phase;
wire [4:0] keycode;
always #5 clk=~clk;

jt12_pg #(.num_ch(3)) uut(
    .clk ( clk ), .clk_en ( 1'b1 ), .rst ( rst ),
    .fnum_I ( 11'd1024 ), .block_I ( 3'd7 ),
    .mul_II ( 4'd1 ), .dt1_I ( 3'd0 ),
    .lfo_mod ( 7'd0 ), .pms_I ( 3'd0 ),
    .pg_rst_II ( 1'b0 ), .pg_stop ( pg_stop ),
    .keycode_II ( keycode ), .phase_VIII ( phase )
);

initial begin
    repeat(3) @(negedge clk);
    rst=0;
    repeat(28) @(negedge clk);
    if (uut.phase_drop===20'd0)
        begin $display("FAIL phase did not advance"); $finish; end
    pg_stop=1;
    #1;
    if (uut.phase_in!==20'd0)
        begin $display("FAIL test reset"); $finish; end
    repeat(26) @(negedge clk);
    if (uut.phase_drop!==20'd0 || phase!==10'd0)
        begin $display("FAIL held test reset"); $finish; end
    pg_stop=0;
    #1;
    if (uut.phase_in===20'd0)
        begin $display("FAIL test reset release"); $finish; end
    $display("PASS"); $finish;
end
endmodule
