module TopModule (
	input logic clk,
	input logic reset,
	output logic [3:0] q
);

	// Sequential logic
	logic [3:0] counter;
	always @(posedge clk) begin
		if (reset)
			counter <= 4'd0;
		else
			counter <= counter + 1;
	end

	// Combinational logic
	assign q = counter;

endmodule