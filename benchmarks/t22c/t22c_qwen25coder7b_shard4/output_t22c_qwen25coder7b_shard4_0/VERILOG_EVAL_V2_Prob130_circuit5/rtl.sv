module TopModule (
	input logic [3:0] a,
	input logic [3:0] b,
	input logic [3:0] c,
	input logic [3:0] d,
	input logic [3:0] e,
	output logic [3:0] q
);

	always @(*) begin
		if (c == 4'd0) begin
			q = b;
		end else if (c == 4'd1) begin
			q = e;
		end else if (c == 4'd2) begin
			q = a;
		end else if (c == 4'd3) begin
			q = d;
		end else begin
			q = 4'b1111; // For don't care cases, set output to a known value (e.g., 15)
		end
	end

endmodule;