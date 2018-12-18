`timescale 1 ns / 1 ps

module test;
/* verilator lint_off STMTDLY */

reg clk, rst;
reg [15:0] fm_data[0:65535];
reg [10:0] psg_data[0:21000];
reg [15:0] fm_snd=16'd0;

initial begin
    $readmemh("data.hex",fm_data);
    $readmemh("psg.hex",psg_data);
end

`ifdef FINISH_AT
initial
    #((`FINISH_AT)*1000_000) $finish;
`endif

initial begin
    rst = 1'b1;
    #50;
    rst = 1'b0;
    //#10000000 $finish;
end

initial begin
    clk = 0;
    forever clk = #19 ~clk;
end

integer psgce_cnt;
reg psg_zero;

always @(posedge clk)
    if( rst ) begin
        psgce_cnt <= 0;
        psg_zero <= 1'b0; 
    end else begin
        if( psgce_cnt == 15*16 ) begin
            psgce_cnt <= 0;
            psg_zero <= 1'b1;
        end else begin
            psgce_cnt <= psgce_cnt+1;
            psg_zero<= 1'b0;
        end
    end

integer psg_cnt;
reg [10:0] psg_snd;

always @(posedge clk)
    if( rst ) begin
        psg_cnt<=0;
        psg_snd <= 11'd0;
    end else if( psg_zero ) begin
        psg_cnt<=psg_cnt==21000 ? 0 : psg_cnt+1;
        psg_snd<=psg_data[psg_cnt];
    end

integer zero_cnt;
reg fm_zero;

always @(posedge clk)
    if( rst ) begin
        zero_cnt <= 0;
        fm_zero  <= 1'b0;
    end else begin
        if( zero_cnt==1007 ) begin
            zero_cnt<=0;
            fm_zero <=1'b1;
        end else begin
            zero_cnt <= zero_cnt+1;
            fm_zero  <= 1'b0;
        end
    end

integer cnt;
always @(posedge clk)
    if( rst ) begin
        cnt<=0;
        fm_snd <= 16'd0;
    end else if( fm_zero ) begin
        cnt<=cnt+1;
        `ifndef NOFM
        fm_snd<=fm_data[cnt<<1];
        `endif
        if(cnt>=30000) $finish;
    end

wire signed [15:0] snd;


jt12_genmix u_mix(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .fm_snd     ( fm_snd    ),
    .psg_snd    ( psg_snd   ),
    .snd        ( snd       )    // Mixed sound at clk sample rate
);


initial begin
    $dumpfile("test.lxt");
    `ifdef DUMP_ALL
        $dumpvars(0, test);
    `endif
    $dumpvars(1, test.u_mix.u_psg2);
    $dumpvars(0,test.fm_snd);
    $dumpvars(0,test.u_mix.fm2);
    $dumpvars(0,test.u_mix.fm3);
    $dumpvars(0,test.u_mix.fm4);
    $dumpvars(0,test.u_mix.fm5);
    $dumpvars(0,test.psg_snd);
    $dumpvars(0,test.u_mix.psg1);
    $dumpvars(0,test.u_mix.psg2);
    $dumpvars(0,test.u_mix.psg3);
    $dumpvars(0,test.u_mix.mixed);
    $dumpon;
end

endmodule // test