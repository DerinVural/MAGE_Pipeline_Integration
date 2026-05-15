module TopModule (
	input logic clk,
	input logic reset,
	input logic w,
	output logic z
);
	localparam STATE_A = 1'b0;
	localparam STATE_B = 1'b1;
	localparam STATE_C = 2'b10;
	localparam STATE_D = 2'b11;
	localparam STATE_E = 3'b111;
	localparam STATE_F = 3'b110;
	logic state;
	logic state_next;

	initial begin
		state = STATE_A;
	end

	always @(posedge clk) begin
		if (reset)
			state <= STATE_A;
		else
			state <= state_next;
	end

	always @(*) begin
		case (state)
			STATE_A:
				if (w)
					state_next = STATE_A;
				else
					state_next = STATE_B;
			STATE_B:
				if (w)
					state_next = STATE_D;
				else
					state_next = STATE_C;
			STATE_C:
				if (w)
					state_next = STATE_D;
				else
					state_next = STATE_E;
			STATE_D:
				if (w)
					state_next = STATE_A;
				else
					state_next = STATE_F;
			STATE_E:
				if (w)
					state_next = STATE_D;
				else
					state_next = STATE_D;
			STATE_F:
				if (w)
					state_next = STATE_C;
				else
					state_next = STATE_D;
			default:
				state_next = STATE_A;
		endcase
	end

	assign z = (state == STATE_C) || (state == STATE_E);

endmodule