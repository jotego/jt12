`timescale 1ns / 1ps

module sincf #(parameter win=1, wout=5)
(
	input clk,
	input [win-1:0] din,
	output reg [wout-1:0] dout
);

reg [win-1:0] mem[23:0];

genvar i;


generate 
for (i=23; i>0; i=i-1) begin: meminput
	always @(posedge clk)
		mem[i] <= mem[i-1];	
end

endgenerate

always @(posedge clk) begin
	mem[0] <= din;
	dout <= mem[0] + mem[1] + mem[2] + mem[3] +
		mem[4] + mem[5] + mem[6] + mem[7] +
		mem[8] + mem[9] + mem[10] + mem[11] +
		mem[12] + mem[13] + mem[14] + mem[15] +
		mem[16] + mem[17] + mem[18] + mem[19] +
		mem[20] + mem[21] + mem[22] + mem[23];
end

endmodule
