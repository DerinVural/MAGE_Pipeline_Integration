module TopModule (
	input logic clk,
	input logic x,
	input logic reset,
	output logic z
);
	parameter STATE_A = 3'b000;
	parameter STATE_B = 3'b001;
	parameter STATE_C = 3'b010;
	parameter STATE_D = 3'b011;
	logic [2:0] state;
	logic [2:0] state_next;
	logic xor_out;
	logic and_out;
	logic or_out;
	logic dff_out_xor;
	logic dff_out_and;
	logic dff_out_or;
	assign xor_out = x ^ dff_out_xor;
	assign and_out = x & ~dff_out_and;
	assign or_out = x | ~dff_out_or;
	assign z = ~(xor_out | and_out | or_out);

	initial begin
		state = STATE_A;
		dff_out_xor = 0;
		dff_out_and = 0;
		dff_out_or = 0;
	end

	always @(posedge clk) begin
		if (reset)
			state <= STATE_A;
		else
			state <= state_next;
	end

	always @(*) begin
		state_next = state;
		case (state)
			STATE_A: if (xor_out) state_next = STATE_B;
			STATE_B: if (and_out) state_next = STATE_C;
			STATE_C: if (or_out) state_next = STATE_D;
			default: state_next = STATE_A;
		endcase
	end

	always @(posedge clk) begin
		case (state)
			STATE_A: dff_out_xor <= 0;
			STATE_B: dff_out_xor <= 1;
			STATE_C: dff_out_xor <= 0;
			STATE_D: dff_out_xor <= 1;
		endcase
		case (state)
			STATE_A: dff_out_and <= 0;
			STATE_B: dff_out_and <= 1;
			STATE_C: dff_out_and <= 1;
			STATE_D: dff_out_and <= 1;
		endcase
		case (state)
			STATE_A: dff_out_or <= 0;
			STATE_B: dff_out_or <= 1;
			STATE_C: dff_out_or <= 1;
			STATE_D: dff_out_or <= 1;
		endcase
	end
endmodule