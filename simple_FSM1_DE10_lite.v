module FSM1(
	input clk,
	input rst_n,
	input in,
	output reg[3:0] out_data
);
	parameter s0 = 0, s1 = 1, s2 = 2 , s3 = 3;
	reg[2:0] state, next_state;

	always @(*)begin
		case(state)
			s0: next_state = in ? s1 : s0;
			s1: next_state = in ? s1 : s2;
			s2: next_state = in ? s3 : s2;
			s3: next_state = in ? s3 : s0;
			default next_state = s0;
		endcase
	end
	
	always @(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			state <= s0;
		end else begin
			state <= next_state;
		end
	end

	always @(*)begin
		case(state)
				s0: out_data <= 4'h0;
				s1: out_data <= 4'h1;
				s2: out_data <= 4'h8;
				s3: out_data <= 4'hf;
				default: out_data <= 4'h0;
			endcase		
	end

endmodule
