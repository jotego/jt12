/* This file is part of JT12.

    JT12 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT12 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT12.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 27-1-2017

*/

module jt12_kon(
    input           rst,
    input           clk,
    input           clk_en /* synthesis direct_enable */,
    input   [3:0]   keyon_op,
    input   [2:0]   keyon_ch,
    input   [1:0]   next_op,
    input   [2:0]   next_ch,
    input           up_keyon,
    input           csm,
    // input            flag_A,
    input           overflow_A,
    input           trigger_A,

    output  reg     keyon_I,
    output  reg     csm_key_I
);

parameter num_ch=6;

wire csr_out;
reg csm_pending, csm_window;

always @(posedge clk) begin
    if (rst || !csm) begin
        csm_pending <= 1'b0;
        csm_window  <= 1'b0;
    end else begin
        if (clk_en && next_op==2'd0 && next_ch==3'd0) begin
            csm_window  <= csm_pending || trigger_A;
            csm_pending <= 1'b0;
        end else if (trigger_A) begin
            if (next_op==2'd0 && next_ch==3'd1)
                csm_window <= 1'b1;
            else
                csm_pending <= 1'b1;
        end
    end
end

always @(posedge clk) if (clk_en) begin
    csm_key_I <= csm && next_ch==3'd2 && csm_window;
end

generate
if(num_ch==6) begin
    always @(posedge clk) if( clk_en ) begin
        keyon_I <= (csm && next_ch==3'd2 && csm_window) || csr_out;
    end

    reg        up_keyon_reg;
    reg  [3:0] tkeyon_op;
    reg  [2:0] tkeyon_ch;
    wire       key_upnow;

    assign key_upnow = up_keyon_reg && (tkeyon_ch==next_ch) && (next_op == 2'd3);

    always @(posedge clk) if( clk_en ) begin
        if (rst)
            up_keyon_reg <= 1'b0;
        if (up_keyon) begin
            up_keyon_reg <= 1'b1;
            tkeyon_op <= keyon_op;
            tkeyon_ch <= keyon_ch;      end
        else if (key_upnow)
            up_keyon_reg <= 1'b0;
     end


    wire middle1;
    wire middle2;
    wire middle3;
    wire din      = key_upnow ? tkeyon_op[3] : csr_out;
    wire mid_din2 = key_upnow ? tkeyon_op[1] : middle1;
    wire mid_din3 = key_upnow ? tkeyon_op[2] : middle2;
    wire mid_din4 = key_upnow ? tkeyon_op[0] : middle3;

    jt12_sh_rst #(.width(1),.stages(6),.rstval(1'b0)) u_konch0(
        .clk    ( clk       ),
        .clk_en ( clk_en    ),
        .rst    ( rst       ),
        .din    ( din       ),
        .drop   ( middle1   )
    );

    jt12_sh_rst #(.width(1),.stages(6),.rstval(1'b0)) u_konch1(
        .clk    ( clk       ),
        .clk_en ( clk_en    ),
        .rst    ( rst       ),
        .din    ( mid_din2  ),
        .drop   ( middle2   )
    );

    jt12_sh_rst #(.width(1),.stages(6),.rstval(1'b0)) u_konch2(
        .clk    ( clk       ),
        .clk_en ( clk_en    ),
        .rst    ( rst       ),
        .din    ( mid_din3  ),
        .drop   ( middle3   )
    );

    jt12_sh_rst #(.width(1),.stages(6),.rstval(1'b0)) u_konch3(
        .clk    ( clk       ),
        .clk_en ( clk_en    ),
        .rst    ( rst       ),
        .din    ( mid_din4  ),
        .drop   ( csr_out   )
    );
end
else begin // 3 channels
    reg din;
    reg [3:0] next_op_hot;

    always @(*) begin
        case( next_op )
            2'd0: next_op_hot = 4'b0001; // S1
            2'd1: next_op_hot = 4'b0100; // S3
            2'd2: next_op_hot = 4'b0010; // S2
            2'd3: next_op_hot = 4'b1000; // S4
        endcase
        din = keyon_ch[1:0]==next_ch[1:0] && up_keyon ? |(keyon_op&next_op_hot) : csr_out;
    end

    always @(posedge clk) if( clk_en ) begin
        keyon_I <= (csm && next_ch==3'd2 && csm_window) || csr_out;
    end

    jt12_sh_rst #(.width(1),.stages(12),.rstval(1'b0)) u_konch1(
        .clk    ( clk       ),
        .clk_en ( clk_en    ),
        .rst    ( rst       ),
        .din    ( din       ),
        .drop   ( csr_out   )
    );
end
endgenerate


endmodule
