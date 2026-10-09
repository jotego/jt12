`timescale 1ns/1ps
module test;
reg clk=0, zero=0;
reg signed [13:0] op=0;
wire signed [15:0] snd;
integer i;
always #5 clk=~clk;

jt03_acc uut(
    .rst ( 1'b0 ), .clk ( clk ), .clk_en ( 1'b1 ),
    .op_result ( op ), .s1_enters ( 1'b0 ),
    .s2_enters ( 1'b0 ), .s3_enters ( 1'b0 ),
    .s4_enters ( 1'b0 ), .zero ( zero ), .alg ( 3'd7 ),
    .snd ( snd )
);

task tick;
begin
    @(posedge clk); #1;
    @(negedge clk);
end
endtask

initial begin
    // Five positives exceed 16 bits; a later negative restores range.
    zero=1; tick(); zero=0;
    for (i=0;i<5;i=i+1) begin op=14'sd8191; tick(); end
    op=-14'sd8192; tick();
    op=0; zero=1; tick();
    if (snd!==16'sd32763)
        begin $display("FAIL overflow cancellation: %0d",snd); $finish; end

    zero=0;
    for (i=0;i<6;i=i+1) begin op=14'sd8191; tick(); end
    op=0; zero=1; tick();
    if (snd!==16'sh7fff)
        begin $display("FAIL positive clip: %0d",snd); $finish; end

    zero=0;
    for (i=0;i<6;i=i+1) begin op=-14'sd8192; tick(); end
    op=0; zero=1; tick();
    if (snd!==16'sh8000)
        begin $display("FAIL negative clip: %0d",snd); $finish; end
    $display("PASS"); $finish;
end
endmodule
