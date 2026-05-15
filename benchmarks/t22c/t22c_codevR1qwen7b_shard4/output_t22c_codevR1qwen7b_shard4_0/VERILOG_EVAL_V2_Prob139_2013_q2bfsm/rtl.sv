module TopModule (input logic clk, input logic resetn, input logic x, input logic y, output logic f, output logic g);

	// State definitions
	localparam STATE_A = 2'b00;
	localparam STATE_B = 2'b01;
	localparam STATE_C = 2'b10;
	localparam STATE_D = 2'b11;

	// State register
	logic [1:0] state, next_state;

	// Counters for y monitoring
	logic [1:0] counter_y;
	logic [1:0] counter_y_next;

	// FSM transitions
	always @(*) begin
		case (state)
			STATE_A: begin
				if (!resetn) next_state = STATE_A;
				else next_state = STATE_B;
			end
			STATE_B: begin
				if (x) next_state = STATE_C; else next_state = STATE_B;
			end
			STATE_C: begin
				if (!x) next_state = STATE_D; else next_state = STATE_C;
			end
			STATE_D: begin
				if (y) begin
					counter_y_next = 2'd3; // Keep g high until reset, reset counter to prevent decrementing
					next_state = STATE_D;
				end else begin
					if (counter_y == 0) next_state = STATE_A; // Timeout after two cycles (counter starts at 2, counts down to 0)
					else begin
						counter_y_next = counter_y - 1;
						next_state = STATE_D;
					end
				end
			end
			default: next_state = STATE_A;
		endcase
	end

	// Sequential block
	always @(posedge clk) begin
		if (!resetn) begin
			state <= STATE_A;
			f <= 1'b0;
			g <= 1'b0;
			counter_y <= 2'd0;
		end
		else begin
			state <= next_state;
			if (state == STATE_A && next_state == STATE_B) begin
				f <= 1'b1;
			end else if (state == STATE_B && x) begin
				f <= 1'b0;
			end

			if (next_state == STATE_D) begin
				g <= 1'b1;
			end else if (counter_y == 0) begin
				g <= 1'b0;
			end
			counter_y <= counter_y_next;
		end
	end

	// Initial assignments
	initial begin
		state = STATE_A;
		f = 0;
		g = 0;
		counter_y = 0;
		// Note: Initial state without reset handled by initial block
	end

endmodule