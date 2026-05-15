module TopModule (
	input logic clk,
	input logic a,
	input logic b,
	input logic c,
	input logic d,
	output logic out
);

	// Initialize out to 0 for combinational logic
	initial begin
		out = 0;
	end

	// Derive the Boolean expression from the Karnaugh map:
	// out = a'b'd + a'c'd + a'b'c + a'b'c'd' + a'bc'd'
	assign out = (~a & ~b & d) | (~a & c & d) | (~a & ~b & c) | (~a & ~b & ~c & d) | (~a & b & ~c & d);

endmodule;