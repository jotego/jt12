`timescale 1ns/1ps
module test;
reg clk=0;
reg [4:0] level=0;
wire [7:0] linear;
integer i;
reg [7:0] expected [0:31];
always #5 clk=~clk;

jt49_exp uut_exp(
    .clk ( clk ), .comp ( 3'd5 ), .din ( level ), .dout ( linear )
);

jt49 #(.COMP(3'd5)) uut(
    .rst_n ( 1'b0 ), .clk ( clk ), .clk_en ( 1'b0 ),
    .addr ( 4'd0 ), .cs_n ( 1'b1 ), .wr_n ( 1'b1 ),
    .din ( 8'd0 ), .sel ( 1'b1 ),
    .dout ( ), .sound ( ), .A ( ), .B ( ), .C ( ), .sample ( ),
    .IOA_in ( 8'd0 ), .IOA_out ( ), .IOA_oe ( ),
    .IOB_in ( 8'd0 ), .IOB_out ( ), .IOB_oe ( )
);

initial begin
    expected[ 0]=0; expected[ 1]=0; expected[ 2]=1; expected[ 3]=2;
    expected[ 4]=3; expected[ 5]=3; expected[ 6]=4; expected[ 7]=5;
    expected[ 8]=6; expected[ 9]=7; expected[10]=8; expected[11]=9;
    expected[12]=11; expected[13]=14; expected[14]=16; expected[15]=18;
    expected[16]=23; expected[17]=27; expected[18]=31; expected[19]=35;
    expected[20]=43; expected[21]=51; expected[22]=60; expected[23]=68;
    expected[24]=84; expected[25]=101; expected[26]=117; expected[27]=132;
    expected[28]=161; expected[29]=192; expected[30]=224; expected[31]=255;
    for (i=0;i<32;i=i+1) begin
        @(negedge clk); level=i[4:0];
        @(posedge clk); #1;
        if (linear!==expected[i])
            begin $display("FAIL LLE level %0d: %0d",i,linear); $finish; end
    end
    uut.regarray[8]=8'd1;
    uut.regarray[9]=8'd7;
    uut.regarray[10]=8'd8;
    #1;
    if (uut.volA!==5'd3 || uut.volB!==5'd15 || uut.volC!==5'd17)
        begin $display("FAIL fixed-volume indexes"); $finish; end
    $display("PASS"); $finish;
end
endmodule
