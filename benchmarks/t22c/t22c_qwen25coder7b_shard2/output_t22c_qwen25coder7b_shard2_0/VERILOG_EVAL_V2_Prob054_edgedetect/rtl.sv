module TopModule(
	input logic clk,
	input logic [7:0] in,
	output logic [7:0] pedge
);

	// Register to store the previous input state
	logic [7:0] prev_in;

	// Instantiate the edge detection module
	double edge_det (
		.clk(clk),
		.curr_in(in),
		.prev_in(prev_in),
		.pedge(pedge)
	);

	// Sequential logic to update previous input state
	always_ff @(posedge clk) begin
		prev_in <= in;
	end

endmodule

// Edge detection submodule
module double (
	input logic clk,
	input logic [7:0] curr_in,
	input logic [7:0] prev_in,
	output logic [7:0] pedge
);

	// Temporary wire to hold the detected edges
	logic [7:0] edge_temp;

	// Combining logic to detect positive edges
	assign edge_temp = (curr_in & ~prev_in);

	// Sequential logic to shift the detected edges by one clock cycle
	always_ff @(posedge clk) begin
		pedge <= edge_temp;
	end

endmodule