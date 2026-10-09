`timescale 1ns/1ps
module test;
reg clk=0, zero=0;
reg signed [8:0] op_12=0;
reg signed [15:0] op_16=0;
wire signed [11:0] snd_12;
wire signed [15:0] snd_16;
integer i;
always #5 clk=~clk;

jt12_single_acc #(.win(9),.wout(12)) uut_12(
    .clk ( clk ), .clk_en ( 1'b1 ),
    .op_result ( op_12 ), .sum_en ( 1'b1 ),
    .zero ( zero ), .snd ( snd_12 )
);

jt12_single_acc #(.win(16),.wout(16)) uut_16(
    .clk ( clk ), .clk_en ( 1'b1 ),
    .op_result ( op_16 ), .sum_en ( 1'b1 ),
    .zero ( zero ), .snd ( snd_16 )
);

task tick;
begin
    @(posedge clk); #1;
    @(negedge clk);
end
endtask

initial begin
    zero=1; tick(); zero=0;
    for (i=0;i<9;i=i+1) begin
        op_12=9'sd255;
        op_16=16'sd32767;
        tick();
    end
    op_12=-9'sd256;
    op_16=-16'sd100;
    tick();
    op_12=0; op_16=0; zero=1; tick();
    if (snd_12!==12'sd1791 || snd_16!==16'sd32667)
        begin $display("FAIL legacy intermediate clipping: %0d %0d",snd_12,snd_16); $finish; end
    $display("PASS"); $finish;
end
endmodule
