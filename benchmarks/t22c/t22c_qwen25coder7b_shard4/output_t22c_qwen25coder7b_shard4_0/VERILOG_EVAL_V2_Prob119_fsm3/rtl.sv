module TopModule(
	input  logic clk,
	input  logic areset,
	input  logic in,
	output logic out
);

typedef enum logic [1:0] {
	STATE_A,
	STATE_B,
	STATE_C,
	STATE_D
} state_t;

state_t state;
state_t next_state;

always_ff @(posedge clk or posedge areset) begin
	if (areset)
		state <= STATE_A;
	else
		state <= next_state;
end

always_comb begin
	next_state = state;
	case (state)
		STATE_A:
			if (in)
				next_state = STATE_B;
			else
				next_state = STATE_A;
		STATE_B:
			if (in)
				next_state = STATE_C;
			else
				next_state = STATE_B;
		STATE_C:
			if (in)
				next_state = STATE_D;
			else
				next_state = STATE_A;
		STATE_D:
			if (in)
				next_state = STATE_B;
			else
				next_state = STATE_C;
	endcase
end

always_comb begin
	out = 0;
	case (state)
		STATE_A:
			out = 0;
		STATE_B:
			out = 0;
		STATE_C:
			out = 0;
		STATE_D:
			out = 1;
	endcase
end

endmodule