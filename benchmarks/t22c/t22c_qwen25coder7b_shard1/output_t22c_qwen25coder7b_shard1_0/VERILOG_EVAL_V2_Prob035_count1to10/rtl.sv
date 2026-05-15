module TopModule (
	input logic clk,
	input logic reset,
	output logic [3:0] q
);

	logic [3:0] count;

	initial begin
		count = 4'd1;
	end

	always_ff @(posedge clk or posedge reset) begin
		if (reset)
			count <= 4'd1;
		else
			count <= (count == 4'd10) ? 4'd1 : count + 1;
	end

	assign q = count;

endmodule