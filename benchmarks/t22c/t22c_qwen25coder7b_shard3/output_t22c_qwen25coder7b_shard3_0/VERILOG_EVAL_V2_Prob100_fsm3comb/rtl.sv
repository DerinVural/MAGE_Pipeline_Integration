module TopModule (
	input logic in,
	input logic [1:0] state,
	input logic clk,
	input logic reset,
	output logic [1:0] next_state,
	output logic out
);
	parameter STATE_A = 2'b00;
	parameter STATE_B = 2'b01;
	parameter STATE_C = 2'b10;
	parameter STATE_D = 2'b11;

	// Initialize state_reg
	logic [1:0] state_reg;
	initial state_reg = STATE_A;

	// Define the next state logic
	always @(*) begin
		case (state)
			STATE_A: next_state = (in == 0) ? STATE_A : STATE_B;
			STATE_B: next_state = (in == 0) ? STATE_C : STATE_B;
			STATE_C: next_state = (in == 0) ? STATE_A : STATE_D;
			STATE_D: next_state = (in == 0) ? STATE_C : STATE_B;
			default: next_state = STATE_A; // This line should never be reached
		endcase
	end

	// Define the output logic
	always @(*) begin
		case (state)
			STATE_A: out = 0;
			STATE_B: out = 0;
			STATE_C: out = 0;
			STATE_D: out = 1;
			default: out = 0; // This line should never be reached
		endcase
	end

	// Update state_reg on rising edge of clk or reset
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state_reg <= STATE_A;
		end else begin
			state_reg <= next_state;
		end
	end

	// Assign next_state to port
	assign next_state = state_reg;

endmodule