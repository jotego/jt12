module jt12_pcm(
    input               rst,
    input               clk,
(* direct_enable *) input clk_en,
    input               zero,
    input   signed [8:0] pcm,
    input               pcm_wr, // runs without gating the clock
    output signed [8:0] pcm_resampled
);

reg [2:0] ratesel;
reg [2:0] cnt8;
reg [3:0] wrcnt;
reg last_zero, wrclr;
wire zero_edge = !last_zero && zero;

always @(posedge clk)
    if(rst) begin
        wrcnt   <= 4'd0;
    end else begin // don't gate the clock to catch pcm_wr
        pcm_wr <= (cnt8==3'd0 && rate1) ? 4'd0 : (pcm_wr ? wrcnt+4'd1 : wrcnt);
    end

always @(posedge clk)
    if(rst) begin
        cnt8    <= 3'd0;
        wrclr   <= 1'd0;
        ratesel <= 3'd0;
    end else if(rate1) begin 
        cnt8 <= cnt8 + 3'd1;
        if( wrcnt==3'd7 )
            case( wrcnt )
                4'd1:      ratesel <= 3'b111; // x8
                4'd2:      ratesel <= 3'b011; // x4
                4'd3,4'd4: ratesel <= 3'b001; // x2
                default:   ratesel <= 3'b000; // x1
            endcase // wrcnt
    end

// up-rate PCM samples
reg zero_cen, zeroin_cen;
reg rate1, rate2, rate4, rate8;
reg cen1, cen2, cen4, cen8;

always @(posedge clk) 
    if(rst)
        rate2 <= 1'b0;
    else begin
        last_zero <= zero;
        rate1 <= zero_edge;
        rate2 <= zero_edge ? ~rate2 : rate2;
        rate4 <= (zero_edge && !rate2) ? ~rate4 : rate4;
        rate8 <= (zero_edge && !rate4) ? ~rate4 : rate4;
    end

reg cen1,cen2,cen4,cen8;
always @(negedge clk) begin
    cen1 <= rate1;
    cen2 <= rate1 && rate2;
    cen4 <= rate1 && rate4;
    cen8 <= rate1 && rate8;
end

wire signed [8:0] pcm2, pcm3, pcm1;

always @(posedge clk) if( clk_en )
    pcm_resampled <= ratesel[0] ? pcm3 : pcm;

// rate x2
wire signed [8:0] pcm_in2 = ratesel[1] ? pcm2 : pcm;
jt12_interpol #(.calcw(11),.inw(9),.rate(2),.m(1),.n(2)) 
u_uprate_3(
    .clk    ( clk         ),
    .rst    ( rst         ),        
    .cen_in ( cen2        ),
    .cen_out( cen1        ),
    .snd_in ( pcm_in2     ),
    .snd_out( pcm3        )
);

// rate x2
wire signed [8:0] pcm_in1 = ratesel[2] ? pcm1 : pcm;
jt12_interpol #(.calcw(11),.inw(9),.rate(2),.m(1),.n(2)) 
u_uprate_2(
    .clk    ( clk         ),
    .rst    ( rst         ),        
    .cen_in ( cen4        ),
    .cen_out( cen2        ),
    .snd_in ( pcm_in1     ),
    .snd_out( pcm2        )
);

// rate x2
jt12_interpol #(.calcw(11),.inw(9),.rate(2),.m(1),.n(2)) 
u_uprate_1(
    .clk    ( clk         ),
    .rst    ( rst         ),        
    .cen_in ( cen8        ),
    .cen_out( cen4        ),
    .snd_in ( pcm         ),
    .snd_out( pcm1        )
);

endmodule // jt12_pcm