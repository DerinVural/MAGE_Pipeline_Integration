module TopModule (input in, input [1:0] state, output logic [1:0] next_state, output logic out);
	// State definitions
	localparam [1:0] A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

	// Next state logic
	always @(*) begin
		case (state)
			A: next_state = in ? B : A;
			B: next_state = in ? C : B;
			C: next_state = in ? D : A;
			D: next_state = in ? C : B;
			default: next_state = A;
		endcase
	end

	// Output logic
	always @(*) begin
		if (state == A) out = 0;
		else if (state == B) out = 0;
		else if (state == C) out = 0;
		else if (state == D) out = 1;
		else out = 0; // default case
	end

	// Initialize outputs and next_state to avoid X (if needed, though in combinational logic they are driven by always @*)
	// initial begin
	//     next_state = A;
	//     out = 0;
	// end
endmodule