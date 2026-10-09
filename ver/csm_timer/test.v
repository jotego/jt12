`timescale 1ns/1ps
module test;
reg clk=0, rst=1, cen=0, zero=0, load=0, clr=0;
reg irq_enable=0;
wire flag, overflow, trigger;
wire wrapper_flag, wrapper_trigger, irq_n;
always #5 clk=~clk;

jt12_timer #(.CW(10)) uut(
    .rst         ( rst       ),
    .clk         ( clk       ),
    .cen         ( cen       ),
    .zero        ( zero      ),
    .start_value ( 10'h3ff  ),
    .load        ( load      ),
    .enable_status ( irq_enable ),
    .clr_flag    ( clr       ),
    .flag        ( flag      ),
    .overflow    ( overflow  ),
    .trigger     ( trigger   )
);

jt12_timers #(.num_ch(3)) uut_timers(
    .clk ( clk ), .rst ( rst ), .clk_en ( cen ), .zero ( zero ),
    .value_A ( 10'h3ff ), .value_B ( 8'd0 ),
    .load_A ( load ), .load_B ( 1'b0 ),
    .clr_flag_A ( clr ), .clr_flag_B ( 1'b0 ),
    .enable_irq_A ( irq_enable ), .enable_irq_B ( 1'b0 ),
    .flag_A ( wrapper_flag ), .flag_B ( ),
    .overflow_A ( ), .trigger_A ( wrapper_trigger ), .irq_n ( irq_n )
);

initial begin
    $dumpfile("test.lxt"); $dumpvars;
    repeat(3) @(negedge clk);
    rst=0;
    load=1;
    #1;
    if (trigger!==1'b1 || wrapper_trigger!==1'b1)
        begin $display("FAIL initial load"); $finish; end
    @(negedge clk);
    if (trigger!==1'b0 || flag!==1'b0) begin $display("FAIL held load"); $finish; end
    cen=1; zero=1;
    #1;
    if (trigger!==1'b1 || wrapper_trigger!==1'b1)
        begin $display("FAIL overflow reload"); $finish; end
    @(negedge clk);
    if (flag!==1'b0 || wrapper_flag!==1'b0 || irq_n!==1'b1)
        begin $display("FAIL disabled overflow set status"); $finish; end
    irq_enable=1;
    #1;
    if (irq_n!==1'b1) begin $display("FAIL late IRQ enable"); $finish; end
    @(negedge clk);
    if (flag!==1'b1 || wrapper_flag!==1'b1 || irq_n!==1'b0)
        begin $display("FAIL enabled overflow status"); $finish; end
    irq_enable=0;
    #1;
    if (irq_n!==1'b0)
        begin $display("FAIL disabling enable cleared latched IRQ"); $finish; end
    zero=0;
    #1;
    if (trigger!==1'b0) begin $display("FAIL clock gate"); $finish; end
    clr=1;
    @(negedge clk);
    if (flag!==1'b0 || wrapper_flag!==1'b0 || irq_n!==1'b1)
        begin $display("FAIL clear flag"); $finish; end
    load=0; clr=0;
    @(negedge clk);
    load=1;
    #1;
    if (trigger!==1'b1 || flag!==1'b0) begin $display("FAIL reload without status"); $finish; end
    $display("PASS"); $finish;
end
endmodule
