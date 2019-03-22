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

reg signed [15:0] pcm_in=16'd0;
reg signed [15:0] sine[0:127];
integer cnt=0;

initial $readmemh("sine.hex", sine);

always @(posedge clk) begin
    ch <= ch==3'd5 ? 3'd0 : (ch+3'd1);
    case( ch )
        3'd0: pcm_in <= sine[ { cnt[4:0], 2'b0 } ] >>> 2;
        3'd5: pcm_in <= sine[cnt];
        default: pcm_in <= 'd0;
    endcase // ch
    if( ch==3'd5 ) cnt <= cnt+1;
    if( cnt==127 ) $finish;
end

reg cen55=1'b1;

always @(negedge clk) cen55 <= ~cen55;

wire [15:0] pcm_out;

jt10_adpcm_acc uut(
    .rst_n  ( rst_n   ),
    .clk    ( clk     ),        // CPU clock
    .cen111 ( 1'b1    ),
    .cen55  ( cen55   ),
    .ch     ( ch      ),
    .pcm_in ( pcm_in  ),
    .pcm_out( pcm_out )
);

endmodule