module test;

initial begin
    $dumpfile("test.vcd");
    $dumpvars;
end

reg clk=1'b0;
reg rst_n = 1'b1;
reg [2:0] ch=3'd0;

initial forever clk = #10 ~clk;
initial begin
    rst_n = #1 1'b0;
    rst_n = #1 1'b1;
end

reg [15:0] pcm_in;
reg [15:0] sine[0:127];
integer cnt=0;

initial $readmemh("sine.hex", sine);

always @(posedge clk) begin
    ch <= ch==3'd5 ? 3'd0 : (ch+3'd1);
    pcm_in <= ch==3'd5 ? sine[cnt] : 16'd0;
    if( ch==3'd5 ) cnt <= cnt+1;
    if( cnt==127 ) $finish;
end

initial #1000 $finish;

wire [15:0] pcm_out;

jt10_adpcm_acc uut(
    .rst_n  ( rst_n   ),
    .clk    ( clk     ),        // CPU clock
    .cen    ( 1'b1    ),        // optional clock enable, if not needed leave as 1'b1
    .ch     ( ch      ),
    .pcm_in ( pcm_in  ),
    .pcm_out( pcm_out )
);

endmodule