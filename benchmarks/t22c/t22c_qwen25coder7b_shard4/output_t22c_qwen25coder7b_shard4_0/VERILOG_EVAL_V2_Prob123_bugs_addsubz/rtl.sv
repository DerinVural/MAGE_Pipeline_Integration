module TopModule (
	input do_sub,
	input [7:0] a,
	input [7:0] b,
	output logic [7:0] out,
	output logic result_is_zero
);

	// Define the sum and difference variables
	logic signed [8:0] sum;
	logic signed [8:0] diff;

	// Calculate the sum and difference based on do_sub
	always @(*) begin
		if (do_sub) begin
			sum = a - b;
			diff = a - b;
		end else begin
			sum = a + b;
			diff = a + b;
		end
	end

	// Assign the output based on do_sub and the calculated values
	assign out = do_sub ? (diff < 0 ? -1 : diff) : sum;

	// Determine if the result is zero
	assign result_is_zero = (out == 0);

endmodule