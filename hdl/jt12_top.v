/*  This file is part of JT12.

    JT12 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT12 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT12.  If not, see <http://www.gnu.org/licenses/>.
    
    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 14-2-2016
    
    Based on information posted by Nemesis on:
http://gendev.spritesmind.net/forum/viewtopic.php?t=386&postdays=0&postorder=asc&start=167

    Based on jt51_phasegen.v, from JT51 
    
    */

module jt12_top (
    input           rst,        // rst should be at least 6 clk&cen cycles long
    input           clk,        // CPU clock
    input           cen,        // optional clock enable, it not needed leave as 1'b1
    input   [7:0]   din,
    input   [1:0]   addr,
    input           cs_n,
    input           wr_n,
    
    output  [7:0]   dout,
    output          irq_n,
    // Separated output
    output          [ 7:0] psg_A,
    output          [ 7:0] psg_B,
    output          [ 7:0] psg_C,
    output  signed  [15:0] fm_snd_left,
    output  signed  [15:0] fm_snd_right,
    // combined output
    output          [ 9:0] psg_snd,
    output  signed  [15:0] snd_right, // FM+PSG
    output  signed  [15:0] snd_left,  // FM+PSG
    output                 snd_sample
);

parameter use_lfo=1, use_ssg=0, num_ch=6, use_pcm=1, use_lr=1; // defaults to YM2612

wire flag_A, flag_B, busy;

wire [7:0] fm_dout = { busy, 5'd0, flag_B, flag_A };
wire write = !cs_n && !wr_n;
wire clk_en, clk_en_ssg;

// Timers
wire    [9:0]   value_A;
wire    [7:0]   value_B;
wire            load_A, load_B;
wire            enable_irq_A, enable_irq_B;
wire            clr_flag_A, clr_flag_B;
wire            overflow_A;
wire            fast_timers;

wire            zero; // Single-clock pulse at the begginig of s1_enters
// LFO
wire    [2:0]   lfo_freq;
wire            lfo_en;
// Operators
wire            amsen_IV;
wire    [ 2:0]  dt1_I;
wire    [ 3:0]  mul_II;
wire    [ 6:0]  tl_IV;

wire    [ 4:0]  keycode_II;
wire    [ 4:0]  ar_I;
wire    [ 4:0]  d1r_I;
wire    [ 4:0]  d2r_I;
wire    [ 3:0]  rr_I;
wire    [ 3:0]  sl_I;
wire    [ 1:0]  ks_II;
// SSG operation
wire            ssg_en_I;
wire    [2:0]   ssg_eg_I;
// envelope operation
wire            keyon_I;
wire    [9:0]   eg_IX;
wire            pg_rst_II;
// Channel
wire    [10:0]  fnum_I;
wire    [ 2:0]  block_I;
wire    [ 1:0]  rl;
wire    [ 2:0]  fb_II;
wire    [ 2:0]  alg_I;
wire    [ 2:0]  pms_I;
wire    [ 1:0]  ams_IV;
// PCM
wire            pcm_en, pcm_wr;
wire    [ 8:0]  pcm;
// Test
wire            pg_stop, eg_stop;

wire    ch6op;

// Operator
wire            xuse_internal, yuse_internal;
wire            xuse_prevprev1, xuse_prev2, yuse_prev1, yuse_prev2;
wire    [ 9:0]  phase_VIII;
wire            s1_enters, s2_enters, s3_enters, s4_enters;
wire            rst_int;
// LFO
wire    [6:0]   lfo_mod;
wire            lfo_rst;
// PSG
wire    [3:0]   psg_addr;
wire    [7:0]   psg_data, psg_dout;
wire            psg_wr_n;

jt12_mmr #(.use_ssg(use_ssg),.num_ch(num_ch),.use_pcm(use_pcm)) 
    u_mmr(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),  // external clock enable
    .clk_en     ( clk_en    ),  // internal clock enable    
    .clk_en_ssg ( clk_en_ssg),  // internal clock enable    
    .din        ( din       ),
    .write      ( write     ),
    .addr       ( addr      ),
    .busy       ( busy      ),
    .ch6op      ( ch6op     ),
    // LFO
    .lfo_freq   ( lfo_freq  ),
    .lfo_en     ( lfo_en    ),
    // Timers
    .value_A    ( value_A   ),
    .value_B    ( value_B   ),
    .load_A     ( load_A    ),
    .load_B     ( load_B    ),
    .enable_irq_A   ( enable_irq_A  ),
    .enable_irq_B   ( enable_irq_B  ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .overflow_A ( overflow_A    ),
    .fast_timers( fast_timers   ),
    // PCM
    .pcm        ( pcm           ),
    .pcm_en     ( pcm_en        ),
    .pcm_wr     ( pcm_wr        ),

    // Operator
    .xuse_prevprev1 ( xuse_prevprev1  ),
    .xuse_internal  ( xuse_internal   ),
    .yuse_internal  ( yuse_internal   ),  
    .xuse_prev2     ( xuse_prev2      ),
    .yuse_prev1     ( yuse_prev1      ),
    .yuse_prev2     ( yuse_prev2      ),
    // PG
    .fnum_I     ( fnum_I    ),
    .block_I    ( block_I   ),
    .pg_stop    ( pg_stop   ),
    // EG
    .rl         ( rl        ),
    .fb_II      ( fb_II     ),
    .alg_I      ( alg_I     ),
    .pms_I      ( pms_I     ),
    .ams_IV     ( ams_IV    ),
    .amsen_IV   ( amsen_IV  ),
    .dt1_I      ( dt1_I     ),
    .mul_II     ( mul_II    ),
    .tl_IV      ( tl_IV     ),

    .ar_I       ( ar_I      ),
    .d1r_I      ( d1r_I     ),
    .d2r_I      ( d2r_I     ),
    .rr_I       ( rr_I      ),
    .sl_I       ( sl_I      ),
    .ks_II      ( ks_II     ),

    .eg_stop    ( eg_stop   ),  
    // SSG operation
    .ssg_en_I   ( ssg_en_I  ),
    .ssg_eg_I   ( ssg_eg_I  ),

    .keyon_I    ( keyon_I   ),
    // Operator
    .zero       ( zero      ),
    .s1_enters  ( s1_enters ),
    .s2_enters  ( s2_enters ),
    .s3_enters  ( s3_enters ),
    .s4_enters  ( s4_enters ),
    // PSG interace
    .psg_addr   ( psg_addr  ),
    .psg_data   ( psg_data  ),
    .psg_wr_n   ( psg_wr_n  )    
);

jt12_timers u_timers( 
    .clk        ( clk           ),
    .clk_en     ( clk_en | fast_timers  ),
    .rst        ( rst           ),
    .value_A    ( value_A       ),
    .value_B    ( value_B       ),
    .load_A     ( load_A        ),
    .load_B     ( load_B        ),
    .enable_irq_A( enable_irq_B ),
    .enable_irq_B( enable_irq_A ),
    .clr_flag_A ( clr_flag_A    ),
    .clr_flag_B ( clr_flag_B    ),
    .flag_A     ( flag_A        ),
    .flag_B     ( flag_B        ),
    .overflow_A ( overflow_A    ),
    .irq_n      ( irq_n         )
);

// YM2203 does not have LFO
generate
if( use_lfo== 1)
    jt12_lfo u_lfo(
        .rst        ( rst       ),
        .clk        ( clk       ),
        .clk_en     ( clk_en    ),
        .zero       ( zero      ),
        `ifdef NOLFO
        .lfo_rst    ( 1'b1      ),
        `else
        .lfo_rst    ( 1'b0      ),
        `endif
        .lfo_en     ( lfo_en    ),
        .lfo_freq   ( lfo_freq  ),
        .lfo_mod    ( lfo_mod   )
    );
else
    assign lfo_mod = 7'd0;
endgenerate

// YM2203/YM2610 have a PSG

generate
    if( use_ssg==1 ) begin        
        jt49 u_psg( // note that input ports are not multiplexed
            .rst_n      ( ~rst      ),
            .clk        ( clk       ),    // signal on positive edge
            .clk_en     ( clk_en_ssg),    // clock enable on negative edge
            .addr       ( psg_addr  ),
            .cs_n       ( 1'b0      ),
            .wr_n       ( psg_wr_n  ),  // write
            .din        ( psg_data  ),
            .sound      ( psg_snd   ),  // combined output
            .A          ( psg_A     ),
            .B          ( psg_B     ),
            .C          ( psg_C     ),
            .dout       ( psg_dout  ),
            .sel        ( 1'b1      )   // half clock speed
        );
        assign snd_left  = fm_snd_left  + { 1'b0, psg_snd[9:0],5'd0}; 
        assign snd_right = fm_snd_right + { 1'b0, psg_snd[9:0],5'd0}; 
        assign dout = addr[0] ? psg_dout : fm_dout;
    end else begin
        assign psg_snd  = 10'd0;
        assign snd_left = fm_snd_left;
        assign snd_right= fm_snd_right;
        assign psg_dout = 8'd0;
        assign dout = fm_dout;
    end
endgenerate


`ifndef TIMERONLY

jt12_pg #(.num_ch(num_ch)) u_pg(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .clk_en     ( clk_en        ),
    // Channel frequency
    .fnum_I     ( fnum_I        ),
    .block_I    ( block_I       ),
    // Operator multiplying
    .mul_II     ( mul_II        ),
    // Operator detuning
    .dt1_I      ( dt1_I         ), // same as JT51's DT1
    // Phase modulation by LFO
    .lfo_mod    ( lfo_mod       ),
    .pms_I      ( pms_I         ),
    // phase operation
    .pg_rst_II  ( pg_rst_II     ),
    .pg_stop    ( pg_stop       ),
    .keycode_II ( keycode_II    ),
    .phase_VIII ( phase_VIII    )
);

wire [9:0] eg_V;

jt12_eg #(.num_ch(num_ch)) u_eg(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .clk_en         ( clk_en        ),
    .zero           ( zero          ),
    .eg_stop        ( eg_stop       ),  
    // envelope configuration
    .keycode_II     ( keycode_II    ),
    .arate_I        ( ar_I          ), // attack  rate
    .rate1_I        ( d1r_I         ), // decay   rate
    .rate2_I        ( d2r_I         ), // sustain rate
    .rrate_I        ( rr_I          ), // release rate
    .sl_I           ( sl_I          ), // sustain level
    .ks_II          ( ks_II         ), // key scale
    // SSG operation
    .ssg_en_I       ( ssg_en_I      ),
    .ssg_eg_I       ( ssg_eg_I      ),
    // envelope operation
    .keyon_I        ( keyon_I       ),
    // envelope number
    .lfo_mod        ( lfo_mod       ),
    .tl_IV          ( tl_IV         ),
    .ams_IV         ( ams_IV        ),
    .amsen_IV       ( amsen_IV      ),

    .eg_V           ( eg_V          ),
    .pg_rst_II      ( pg_rst_II     )
);

jt12_sh #(.width(10),.stages(4)) u_egpad(
    .clk    ( clk       ),
    .clk_en ( clk_en    ),
    .din    ( eg_V      ),
    .drop   ( eg_IX     )
);

wire    [ 8:0]  op_result;
wire    [13:0]  full_result;

jt12_op #(.num_ch(num_ch)) u_op(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .clk_en         ( clk_en        ),
    .pg_phase_VIII  ( phase_VIII    ),
    .eg_atten_IX    ( eg_IX         ),
    .fb_II          ( fb_II         ),

    .test_214       ( 1'b0          ),
    .s1_enters      ( s1_enters     ),
    .s2_enters      ( s2_enters     ),
    .s3_enters      ( s3_enters     ),
    .s4_enters      ( s4_enters     ),
    .xuse_prevprev1 ( xuse_prevprev1),
    .xuse_internal  ( xuse_internal ),
    .yuse_internal  ( yuse_internal ),  
    .xuse_prev2     ( xuse_prev2    ),
    .yuse_prev1     ( yuse_prev1    ),
    .yuse_prev2     ( yuse_prev2    ),
    .zero           ( zero          ),
    .op_result      ( op_result     ),
    .full_result    ( full_result   )
);

generate
    if( use_lr==1 ) begin
        assign fm_snd_right[3:0] = 4'd0;
        assign fm_snd_left [3:0] = 4'd0;
        assign snd_sample        = zero;
        wire signed [8:0] pcm2;

        // interpolate PCM samples with automatic sample rate detection
        // this feature is not present in original YM2612
        // this improves PCM sample sound greatly
        jt12_pcm u_pcm(
            .rst        ( rst       ),
            .clk        ( clk       ),
            .clk_en     ( clk_en    ),
            .zero       ( zero      ),
            .pcm        ( pcm       ),
            .pcm_wr     ( pcm_wr    ),
            .pcm_resampled ( pcm2   )
        );

        jt12_acc #(.num_ch(num_ch)) u_acc(
            .rst        ( rst       ),
            .clk        ( clk       ),
            .clk_en     ( clk_en    ),
            .op_result  ( op_result ),
            .rl         ( rl        ),
            // note that the order changes to deal 
            // with the operator pipeline delay
            .zero       ( zero      ),
            .s1_enters  ( s2_enters ),
            .s2_enters  ( s1_enters ),
            .s3_enters  ( s4_enters ),
            .s4_enters  ( s3_enters ),
            .ch6op      ( ch6op     ),
            .pcm_en     ( pcm_en    ),  // only enabled for channel 6
            .pcm        ( pcm2      ),
            .alg        ( alg_I     ),
            // combined output
            .left       ( fm_snd_left [15:4]  ),
            .right      ( fm_snd_right[15:4]  )
        );
    end else begin
        wire signed [15:0] mono_snd;
        assign fm_snd_left  = mono_snd;
        assign fm_snd_right = mono_snd;
        assign snd_sample   = zero;
        jt03_acc u_acc(
            .rst        ( rst       ),
            .clk        ( clk       ),
            .clk_en     ( clk_en    ),
            .op_result  ( full_result ),
            // note that the order changes to deal 
            // with the operator pipeline delay
            .s1_enters  ( s1_enters ),
            .s2_enters  ( s2_enters ),
            .s3_enters  ( s3_enters ),
            .s4_enters  ( s4_enters ),
            .alg        ( alg_I     ),
            .zero       ( zero      ),
            // combined output
            .snd        ( mono_snd  )
        );        
    end    
endgenerate
`endif
endmodule
