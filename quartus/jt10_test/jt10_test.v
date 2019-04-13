module jt10_test(
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, if not needed leave as 1'b1
    input   [7:0]   din,
    input   [1:0]   addr,
    input           cs_n,
    input           wr_n,
    
    output  [7:0]   dout,
    output          irq_n,
    // ADPCM pins
    output  [19:0]  adpcma_addr,  // real hardware has 10 pins multiplexed through RMPX pin
    output  [3:0]   adpcma_bank,
    output          adpcma_roe_n, // ADPCM-A ROM output enable
    input   [7:0]   adpcma_data,  // Data from RAM
    output  [23:0]  adpcmb_addr,  // real hardware has 12 pins multiplexed through PMPX pin
    output          adpcmb_roe_n, // ADPCM-B ROM output enable
    // combined output
    output  signed  [15:0] snd_right,
    output  signed  [15:0] snd_left,
    output          snd_sample    
);

    wire [7:0] psg_A;
    wire [7:0] psg_B;
    wire [7:0] psg_C;
    wire signed [15:0] fm_snd;
    wire [9:0] psg_snd;

jt10 uut (
    .rst         (rst         ),
    .clk         (clk         ),
    .cen         (cen         ),
    .din         (din         ),
    .addr        (addr        ),
    .cs_n        (cs_n        ),
    .wr_n        (wr_n        ),
    .dout        (dout        ),
    .irq_n       (irq_n       ),
    .adpcma_addr (adpcma_addr ),
    .adpcma_bank (adpcma_bank ),
    .adpcma_roe_n(adpcma_roe_n),
    .adpcma_data (adpcma_data ),
    .adpcmb_addr (adpcmb_addr ),
    .adpcmb_roe_n(adpcmb_roe_n),
    .psg_A       (psg_A       ),
    .psg_B       (psg_B       ),
    .psg_C       (psg_C       ),
    .fm_snd      (fm_snd      ),
    .psg_snd     (psg_snd     ),
    .snd_right   (snd_right   ),
    .snd_left    (snd_left    ),
    .snd_sample  (snd_sample  )
);

endmodule