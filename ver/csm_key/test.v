`timescale 1ns/1ps
module test;
reg clk=0, rst=1, clk_en=1, csm=1, trigger=0;
reg [1:0] op3=0, op6=0;
reg [2:0] ch3=0, ch6=0;
wire key3, key6, pulse3, pulse6;
integer i, count3=0, count6=0;
always #5 clk=~clk;

jt12_kon #(.num_ch(3)) uut_3(
    .rst ( rst ), .clk ( clk ), .clk_en ( clk_en ),
    .keyon_op ( 4'd0 ), .keyon_ch ( 3'd0 ),
    .next_op ( op3 ), .next_ch ( ch3 ), .up_keyon ( 1'b0 ),
    .csm ( csm ), .overflow_A ( 1'b0 ), .trigger_A ( trigger ),
    .keyon_I ( key3 ), .csm_key_I ( pulse3 )
);
jt12_kon #(.num_ch(6)) uut_6(
    .rst ( rst ), .clk ( clk ), .clk_en ( clk_en ),
    .keyon_op ( 4'd0 ), .keyon_ch ( 3'd0 ),
    .next_op ( op6 ), .next_ch ( ch6 ), .up_keyon ( 1'b0 ),
    .csm ( csm ), .overflow_A ( 1'b0 ), .trigger_A ( trigger ),
    .keyon_I ( key6 ), .csm_key_I ( pulse6 )
);

initial begin
    $dumpfile("test.lxt"); $dumpvars;
    repeat(30) @(negedge clk);
    rst=0; clk_en=0; trigger=1;
    @(negedge clk); trigger=0;
    repeat(4) @(negedge clk);
    clk_en=1;
    for(i=0;i<24;i=i+1) begin
        op3=(i/3)%4; ch3=i%3;
        op6=i/6;
        case(i%6)
            0: ch6=0; 1: ch6=1; 2: ch6=2;
            3: ch6=4; 4: ch6=5; 5: ch6=6;
        endcase
        @(posedge clk); #1;
        if(i<12) begin
            if(pulse3 !== (ch3==2) || key3 !== (ch3==2)) begin
                $display("FAIL YM2203 slot %0d",i); $finish;
            end
            if(ch3==2) count3=count3+1;
        end else if(pulse3 !== 1'b0) begin
            $display("FAIL YM2203 pulse length"); $finish;
        end
        if(pulse6 !== (ch6==2) || key6 !== (ch6==2)) begin
            $display("FAIL YM2612 slot %0d",i); $finish;
        end
        if(ch6==2) count6=count6+1;
        @(negedge clk);
    end
    op3=0; ch3=0; op6=0; ch6=0;
    @(posedge clk); #1;
    @(negedge clk);
    op3=0; ch3=2; op6=0; ch6=2;
    @(posedge clk); #1;
    if(pulse3!==0 || pulse6!==0 || count3!=4 || count6!=4) begin
        $display("FAIL CSM release"); $finish;
    end
    @(negedge clk);
    op3=0; ch3=1; op6=0; ch6=1; trigger=1;
    @(posedge clk); #1;
    @(negedge clk);
    ch3=2; ch6=2; trigger=0;
    @(posedge clk); #1;
    if(pulse3!==1 || pulse6!==1) begin
        $display("FAIL reload before first channel-3 slot"); $finish;
    end
    @(negedge clk);
    csm=0; trigger=1;
    @(negedge clk); trigger=0;
    @(posedge clk); #1;
    if(pulse3!==0 || pulse6!==0) begin $display("FAIL mode gate"); $finish; end
    @(negedge clk);
    csm=1; op3=0; ch3=0; op6=0; ch6=0;
    @(posedge clk); #1;
    @(negedge clk);
    ch3=2; ch6=2;
    @(posedge clk); #1;
    if(pulse3!==0 || pulse6!==0) begin
        $display("FAIL stale trigger after mode change"); $finish;
    end
    $display("PASS"); $finish;
end
endmodule
