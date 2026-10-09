`timescale 1ns/1ps
module test;
reg clk=0, rst=1, cen=1, addr=0, cs_n=1, wr_n=1;
reg [7:0] din=0;
integer keys=0, i, maxfm=0, magnitude;
reg monitor_audio=0;
wire irq_n;
wire signed [15:0] fm_snd;
always #5 clk=~clk;

jt03 uut(
    .rst ( rst ), .clk ( clk ), .cen ( cen ),
    .din ( din ), .addr ( addr ), .cs_n ( cs_n ), .wr_n ( wr_n ),
    .dout ( ), .irq_n ( irq_n ),
    .IOA_in ( 8'd0 ), .IOB_in ( 8'd0 ),
    .IOA_out ( ), .IOB_out ( ), .IOA_oe ( ), .IOB_oe ( ),
    .psg_A ( ), .psg_B ( ), .psg_C ( ), .fm_snd ( fm_snd ),
    .psg_snd ( ), .snd ( ), .snd_sample ( ), .debug_view ( )
);

always @(posedge clk) if(!rst && uut.u_jt12.clk_en && uut.u_jt12.csm_key_I)
    keys=keys+1;
always @(posedge clk) if(monitor_audio) begin
    magnitude=$signed(fm_snd);
    if(magnitude<0) magnitude=-magnitude;
    if(magnitude>maxfm) maxfm=magnitude;
end

task write_reg(input [7:0] regnum, input [7:0] value);
begin
    @(negedge clk); addr=0; din=regnum; cs_n=0; wr_n=0;
    @(negedge clk); cs_n=1; wr_n=1;
    @(negedge clk); addr=1; din=value; cs_n=0; wr_n=0;
    @(negedge clk); cs_n=1; wr_n=1;
    repeat(100) @(negedge clk);
end
endtask

initial begin
    $dumpfile("test.lxt"); $dumpvars;
    repeat(300) @(negedge clk);
    rst=0;
    write_reg(8'hb2,8'h07); // channel 3, all operators to output
    write_reg(8'h32,8'h01); // operator 1 multiplier
    write_reg(8'h42,8'h00); // operator 1 TL
    write_reg(8'h52,8'h1f); // fast attack
    write_reg(8'h62,8'h1f); // fast decay
    write_reg(8'h72,8'h1f);
    write_reg(8'h82,8'h0f); // fast release
    write_reg(8'ha6,8'h22);
    write_reg(8'ha2,8'h00);
    write_reg(8'had,8'h22);
    write_reg(8'ha9,8'h00);
    write_reg(8'h24,8'h00);
    write_reg(8'h25,8'h00);
    write_reg(8'h27,8'h80);
    if(uut.u_jt12.csm_mode!==1'b1 || irq_n!==1'b1)
        begin $display("FAIL CSM mode"); $finish; end
    write_reg(8'h27,8'h81);
    repeat(250) @(negedge clk);
    if(keys!=4 || irq_n!==1'b1)
        begin $display("FAIL initial Timer A load: %0d keys",keys); $finish; end
    write_reg(8'h27,8'hc0);
    keys=0;
    write_reg(8'h27,8'hc1);
    repeat(250) @(negedge clk);
    if(keys!=0 || uut.u_jt12.csm_mode!==1'b0)
        begin $display("FAIL mode 3 gate: %0d keys",keys); $finish; end
    write_reg(8'h24,8'hff);
    write_reg(8'h25,8'h02); // Timer A = 0x3fe: overflow every two scans
    write_reg(8'h27,8'h80);
    write_reg(8'h27,8'h81);
    keys=0;
    monitor_audio=1;
    repeat(1500) @(negedge clk);
    if(keys<12 || irq_n!==1'b1 || uut.u_jt12.flag_A!==1'b0 || maxfm<10)
        begin $display("FAIL Timer A overflows: %0d keys, FM peak %0d, fm %h eg %h op %h phase %h",keys,maxfm,fm_snd,uut.u_jt12.eg_V,uut.u_jt12.op_result,uut.u_jt12.phase_VIII); $finish; end
    $display("CSM FM peak: %0d",maxfm);
    $display("PASS"); $finish;
end
endmodule
