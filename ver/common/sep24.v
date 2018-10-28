module sep24 #(parameter width=10, parameter pos0=5'd0)
(
	input 	clk,
	input	clk_en,
	input [width-1:0] mixed,
	input [23:0] mask,
	input [4:0] cnt,	
	
	output reg [width-1:0] ch0s1,
	output reg [width-1:0] ch1s1,
	output reg [width-1:0] ch2s1,
	output reg [width-1:0] ch3s1,
	output reg [width-1:0] ch4s1,
	output reg [width-1:0] ch5s1,

	output reg [width-1:0] ch0s2,
	output reg [width-1:0] ch1s2,
	output reg [width-1:0] ch2s2,
	output reg [width-1:0] ch3s2,
	output reg [width-1:0] ch4s2,
	output reg [width-1:0] ch5s2,

	output reg [width-1:0] ch0s3,
	output reg [width-1:0] ch1s3,
	output reg [width-1:0] ch2s3,
	output reg [width-1:0] ch3s3,
	output reg [width-1:0] ch4s3,
	output reg [width-1:0] ch5s3,

	output reg [width-1:0] ch0s4,
	output reg [width-1:0] ch1s4,
	output reg [width-1:0] ch2s4,
	output reg [width-1:0] ch3s4,
	output reg [width-1:0] ch4s4,
	output reg [width-1:0] ch5s4,
	
	output reg [width-1:0] alland,
	output reg [width-1:0] allor );

reg [4:0] cntadj;

/* verilator lint_off WIDTH */
always @(*)
	cntadj = (cnt+pos0)%24;
/* verilator lint_on WIDTH */

always @(posedge clk) if( clk_en ) begin
	case( cntadj )
		5'd0: ch0s1 <= mixed;
		5'd1: ch1s1 <= mixed;
		5'd2: ch2s1 <= mixed;
		5'd3: ch3s1 <= mixed;  		   
		5'd4: ch4s1 <= mixed;
		5'd5: ch5s1 <= mixed;
		
		5'd6: ch0s3 <= mixed;
		5'd7: ch1s3 <= mixed;
		5'd8: ch2s3 <= mixed;
		5'd9: ch3s3 <= mixed;  		   
		5'ha: ch4s3 <= mixed;
		5'hb: ch5s3 <= mixed; 

		5'hc: ch0s2 <= mixed;
		5'hd: ch1s2 <= mixed;
		5'he: ch2s2 <= mixed;
		5'hf: ch3s2 <= mixed;  		   
		5'h10: ch4s2 <= mixed;
		5'h11: ch5s2 <= mixed;    
		
		5'h12: ch0s4 <= mixed;
		5'h13: ch1s4 <= mixed;
		5'h14: ch2s4 <= mixed;
		5'h15: ch3s4 <= mixed; 			   
		5'h16: ch4s4 <= mixed;
		5'h17: ch5s4 <= mixed; 		   
		default:;
	endcase
	
	alland <= 	({width{~mask[0]}} | ch0s1) &
				({width{~mask[1]}} | ch1s1) &
				({width{~mask[2]}} | ch2s1) &
				({width{~mask[3]}} | ch3s1) &
				({width{~mask[4]}} | ch4s1) &
				({width{~mask[5]}} | ch5s1) &
				({width{~mask[6]}} | ch0s2) &
				({width{~mask[7]}} | ch1s2) &
				({width{~mask[8]}} | ch2s2) &
				({width{~mask[9]}} | ch3s2) &
				({width{~mask[10]}} | ch4s2) &
				({width{~mask[11]}} | ch5s2) &
				({width{~mask[12]}} | ch0s3) &
				({width{~mask[13]}} | ch1s3) &
				({width{~mask[14]}} | ch2s3) &
				({width{~mask[15]}} | ch3s3) &
				({width{~mask[16]}} | ch4s3) &
				({width{~mask[17]}} | ch5s3) &
				({width{~mask[18]}} | ch0s4) &
				({width{~mask[19]}} | ch1s4) &
				({width{~mask[20]}} | ch2s4) &
				({width{~mask[21]}} | ch3s4) &
				({width{~mask[22]}} | ch4s4) &
				({width{~mask[23]}} | ch5s4);

	allor <= 	({width{mask[0]}} & ch0s1) |
				({width{mask[1]}} & ch1s1) |
				({width{mask[2]}} & ch2s1) |
				({width{mask[3]}} & ch3s1) |
				({width{mask[4]}} & ch4s1) |
				({width{mask[5]}} & ch5s1) |
				({width{mask[6]}} & ch0s2) |
				({width{mask[7]}} & ch1s2) |
				({width{mask[8]}} & ch2s2) |
				({width{mask[9]}} & ch3s2) |
				({width{mask[10]}} & ch4s2) |
				({width{mask[11]}} & ch5s2) |
				({width{mask[12]}} & ch0s3) |
				({width{mask[13]}} & ch1s3) |
				({width{mask[14]}} & ch2s3) |
				({width{mask[15]}} & ch3s3) |
				({width{mask[16]}} & ch4s3) |
				({width{mask[17]}} & ch5s3) |
				({width{mask[18]}} & ch0s4) |
				({width{mask[19]}} & ch1s4) |
				({width{mask[20]}} & ch2s4) |
				({width{mask[21]}} & ch3s4) |
				({width{mask[22]}} & ch4s4) |
				({width{mask[23]}} & ch5s4);
				
end
	
endmodule
	
