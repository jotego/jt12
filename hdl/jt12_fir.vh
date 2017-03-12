reg signed [coeff_width-1:0] coeff[0:(stages-1)/2];

wire signed [data_width-1:0] mem_left, mem_right;

// pointers
reg [addr_width-1:0] addr_left, addr_right, 
	forward, rev, in_pointer,
	forward_next, rev_next,in_pointer_next;
	
reg update, last_sample;

reg	[1:0]	state;
parameter IDLE=2'b00, LEFT=2'b01, RIGHT=2'b10;

jt12_fir_ram #(.data_width(data_width),.addr_width(addr_width)) chain_left(
	.clk	( clk		),
	.data	( left_in 	),
	.addr	( addr_left ),
	.we		( update	),
	.q		( mem_left	)
);

jt12_fir_ram #(.data_width(data_width),.addr_width(addr_width)) chain_right(
	.clk	( clk		),
	.data	( right_in 	),
	.addr	( addr_right),
	.we		( update	),
	.q		( mem_right)
);
	

always @(posedge clk)
	if( rst )
		{ update, last_sample } <= 2'b00;
	else begin
		last_sample <= sample;
		update <= sample && !last_sample;
	end

parameter mac_width=data_width+coeff_width+1;
parameter acc_width=mac_width+3;
reg	signed [acc_width-1:0] acc_left, acc_right;
(* multstyle = "dsp" *) reg signed [mac_width-1:0] mac;
//integer acc,mac;
reg [5:0] 	cnt, next;

reg signed [data_width:0] sum;
reg signed [coeff_width-1:0] gain;

wire last_stage = cnt==(stages-1)/2;

//integer a,b;

always @(*) begin
	if( state==LEFT) begin	
		if( last_stage )
			sum <= buffer_left;
		else
			sum <= buffer_left + mem_left;
		end
	else begin
		if( last_stage )
			sum <= buffer_right;
		else
			sum <= buffer_right + mem_right;
	end
	gain <= coeff[cnt];
	mac <= gain*sum;
	next <= cnt+1'b1;
end

reg signed [data_width-1:0] buffer_left, buffer_right;


always @(*)  begin
	in_pointer_next <= in_pointer - 1'b1;
	forward_next <= forward+1'b1;
	rev_next <= rev-1'b1;
	case( state )
		default: begin
			addr_left <= update ? rev : in_pointer;
			addr_right<= in_pointer;
		end
		LEFT: begin
			addr_left <= forward_next;
			addr_right<= rev;
		end
		RIGHT: begin
			if( cnt==(stages-1)/2 ) begin
				addr_left <= in_pointer_next;
				addr_right<= in_pointer_next;
			end
			else begin
				addr_left <= rev_next;
				addr_right<= forward;
			end
		end
	endcase
end

always @(posedge clk)
if( rst ) begin
	sample_out <= 1'b0;
	state	<= IDLE;
	in_pointer <= 7'd0;	
	//addr_left <= in_pointer;
	//addr_right<= in_pointer;
end else begin
	case(state)
		default: begin
			if( update ) begin
				state <= LEFT;
				buffer_left <= left_in;
				//addr_left <= rev;
			end
			cnt <= 6'd0;
			acc_left <= {acc_width{1'b0}};
			acc_right <= {acc_width{1'b0}};	
			rev <= in_pointer+stages-1'b1;
			forward <= in_pointer;			
			sample_out <= 1'b0;
		end
		LEFT: begin
				acc_left <= acc_left + mac;
				//addr_left <= forward_next;
				
				buffer_right <= mem_right;
				//addr_right <= rev;
				
				forward<=forward_next;
				state <= RIGHT;
			end
		RIGHT:
			if( cnt==(stages-1)/2 ) begin
				left_out  <= acc_left;
				right_out <= acc_right+mac;
				sample_out <= 1'b1;
				in_pointer  <= in_pointer_next;
				//addr_left <= in_pointer_next;
				//addr_right<= in_pointer_next;
				state <= IDLE;
			end else begin
				acc_right <= acc_right + mac;
				//addr_right <= forward;
				
				buffer_left <= mem_left;
				//addr_left <= rev_next;
				cnt<=next;
				rev<=rev-1'b1;
				state <= LEFT;
			end
	endcase
end
