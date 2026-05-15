module TopModule (input clk, input reset, input s, input w, output logic z);
	localparam STATE_A = 1'b0;
	localparam STATE_B = 1'b1;
	logic state, prev_state;
	logic [2:0] w_history;
	reg [2:0] count;
	reg [2:0] idx;
	
	initial begin
		prev_state = STATE_A;
		state = STATE_A;
		w_history = 3'b000;
		count = 0;
		idx = 0;
		z = 0;
	end
	
	always @(posedge clk) begin
		if (reset) begin
			state <= STATE_A;
			count <= 0;
			idx <= 0;
			z <= 0;
		end else begin
			if (state == STATE_A) begin
				if (s) begin
					state <= STATE_B;
					w_history <= 3'b000;
					idx <= 0;
					count <= 0;
				end
			end else begin
				state <= STATE_A;
			end
		end
	end
	
	// Capture w in history when in state B
	always @(posedge clk) begin
		if (state == STATE_B && !reset) begin
			w_history <= {w_history[1:0], w};
			idx <= idx + 1;
			if (idx == 2) begin
				count <= w_history[2] + w_history[1] + w_history[0];
				idx <= 0;
				z <= (count == 2) ? 1'b1 : 1'b0;
			end
		end
	end
endmodule