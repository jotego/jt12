module jt12_pcm(
    input               rst,
    input               clk,
    input               clk_en /* synthesis direct_enable */,
    input               zero,
    input   signed [8:0] pcm,
    input               pcm_wr, 
    output reg signed [8:0] pcm_resampled
);

reg last_zero;
wire zero_edge = !last_zero && zero;

// up-rate PCM samples
reg rate1, rate2; //, rate4, rate8;
reg cen1, cen2; //, cen4, cen8;

always @(posedge clk, posedge rst) begin
    if(rst)
        rate2 <= 1'b0;
    else begin
        last_zero <= zero;
        rate1 <= zero_edge;
        if(zero_edge) begin
            rate2 <= ~rate2;
        end
    end
end

always @(posedge clk) begin
    cen1 <= rate1;
    cen2 <= rate1 && rate2;
end

wire signed [8:0] pcm3; //,pcm2, pcm1;

always @(*) begin
    pcm_resampled = pcm3;
end

// rate x2
jt12_interpol #(.calcw(10),.inw(9),.rate(2),.m(1),.n(2)) 
u_uprate_3(
    .clk    ( clk         ),
    .rst    ( rst         ),        
    .cen_in ( cen2        ),
    .cen_out( cen1        ),
    // .snd_in ( pcm_in2     ),
    .snd_in ( pcm         ),
    .snd_out( pcm3        )
);

endmodule // jt12_pcm
