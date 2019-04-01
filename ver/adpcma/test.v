module test;

wire signed [15:0] pcm;

reg clk;
initial begin
    clk = 1'b0;
    #100_000;
    forever clk = #(54054/2) ~clk;
end

reg rst_n;
initial begin
    rst_n = 1;
    rst_n = #20000 0;
    rst_n = #50000 1;
end

reg [7:0] mem[0:8*1024*1024];
integer file, maxcnt, cnt;
initial begin
    // 2.rom is obtained by running the verilator simulation
    // on track 02 of Metal Slug
    file=$fopen("2.rom","rb");
    maxcnt = $fread( mem, file );
    $display("INFO 0x%X bytes read", maxcnt);
    cnt    = 32'h2b1b00;
    maxcnt = 32'h2b2e00;
    //$fclose(file);
end

reg nibble=1;

reg [3:0] data=4'd0;

integer chcnt=0;
always @(posedge clk)
    chcnt <= chcnt==5 ? 0 : chcnt+1;

reg chon=1'b0;
wire [7:0] memcnt = mem[cnt];

always @(posedge clk) begin
    if(chcnt==0) begin
        data <= nibble ? memcnt[7:6] : memcnt[3:0];
        nibble <= ~nibble;
        if( !nibble ) cnt <= cnt+1;
        if( cnt == maxcnt ) $finish;    
    end
    chon <= chcnt==0;
end

jt10_adpcm uut(
    .rst_n      ( rst_n ),
    .clk        ( clk   ),
    .cen        ( 1'b1  ),
    .data       ( data  ),
    .chon       ( chon  ),
    .pcm        ( pcm   )
);

wire signed [15:0] pcm_single;

reg cen6=0;

always @(negedge clk ) cen6= chcnt==0;

adpcma_single single(
    .clk        ( clk && cen6         ),
    .data       ( data         ),
    .pcm        ( pcm_single   )
);

reg signed [15:0] pcm0;
always @(posedge clk) begin
    if(chcnt==2) pcm0 <= pcm;
end

initial begin
    $shm_open("test.shm");
    $shm_probe(test,"AS");
end

endmodule