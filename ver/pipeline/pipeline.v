module pipeline;

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    #1000 $finish;
end

reg clk=0;
initial forever clk = #5 ~clk;

// wire [3:0] a1;
reg [7:0] a1, a2, a3, a4, a5, a6;

reg [7:0] sum[0:5];
reg rst=1'b1;
initial rst = #15 1'b0;

initial begin
    sum[0] = 1;
    sum[1] = 1;
    sum[2] = 1;
    sum[3] = 1;
    sum[4] = 1;
    sum[5] = 1;
end

integer idx=0;

always @(posedge clk) if( rst ) begin
    a1 <= 8'd10;
    a2 <= 8'd20;
    a3 <= 8'd30;
    a4 <= 8'd40;
    a5 <= 8'd50;
    a6 <= 8'd60;
end else begin
    idx <= idx==5 ? 0 : idx+1;
    a2 <= a1 + sum[idx];
    a3 <= a2;
    a4 <= a3;
    a5 <= a4;
    a6 <= a5;
    a1 <= a6;
end
/*
jt12_sh_rst #( .width(4), .stages(2)) u_step_data(
    .clk    ( clk       ),
    .clk_en ( 1'b1      ),
    .rst    ( rst       ),  
    .din    ( a5        ),
    .drop   ( a1        )
);
assign a1 = a6;
*/

endmodule