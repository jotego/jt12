`timescale 1ns / 1ps

module test;

reg rst_n, clk, start;
reg  [15:0] a, b;
wire [15:0] d,r;

initial begin
    rst_n = 1'b1;
    #5 rst_n = 1'b0;
    #7 rst_n = 1'b1;
end

initial begin
    clk = 1'b0;
    #10;
    forever #10 clk = ~clk;
end

wire [15:0] check = b*d+r;

initial begin
    a = 16'd1235;
    b = 16'd23;
    start = 0;
    #20;
    start = 1;
    #40 start = 0;

    #(36*20);
    a = 16'd3235;
    b = 16'd123;
    start = 0;
    #20;
    start = 1;
    #40 start = 0;

    #(36*20);
    a = 16'd32767;
    b = 16'd1;
    start = 0;
    #20;
    start = 1;
    #40 start = 0;

    #(36*20);
    a = 16'd100;
    b = 16'd1000;
    start = 0;
    #20;
    start = 1;
    #40 start = 0;

    #(36*20);
    a = 16'd28000;
    b = 16'd14000;
    start = 0;
    #20;
    start = 1;
    #40 start = 0;

    $finish;
end

jt10_adpcm_div #(.dw(16))uut(
    .rst_n  ( rst_n     ),
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    .start  ( start     ),
    .a      ( a     ),
    .b      ( b     ),
    .d      ( d     ),
    .r      ( r     )
);

`ifdef NCVERILOG
initial begin
    $shm_open("test.shm");
    $shm_probe(test,"AS");
end
`else 
initial begin
    $dumpfile("test.fst");
    $dumpvars;
end
`endif

endmodule // test