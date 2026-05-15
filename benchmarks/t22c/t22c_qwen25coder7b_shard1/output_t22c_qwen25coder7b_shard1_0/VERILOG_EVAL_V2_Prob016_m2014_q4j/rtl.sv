module top_module (
	input logic [3:0] x,
	input logic [3:0] y,
	output logic [4:0] sum
);

	// Initialize carry chain
	wire [3:0] c;
	assign c[0] = 0;
	assign c[1] = c[0];
	assign c[2] = c[1];
	assign c[3] = c[2];

	// Full Adder Components
	partial_adder pa0 (.a(x[0]), .b(y[0]), .cin(c[0]), .s(sum[0]), .cout(c[1]));
	partial_adder pa1 (.a(x[1]), .b(y[1]), .cin(c[1]), .s(sum[1]), .cout(c[2]));
	partial_adder pa2 (.a(x[2]), .b(y[2]), .cin(c[2]), .s(sum[2]), .cout(c[3]));
	partial_adder pa3 (.a(x[3]), .b(y[3]), .cin(c[3]), .s(sum[3]), .cout(sum[4]));

endmodule

module partial_adder (
	input logic a,
	input logic b,
	input logic cin,
	output logic s,
	output logic cout
);

	assign {cout, s} = a + b + cin;

endmodule