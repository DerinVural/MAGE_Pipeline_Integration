module TopModule (
	input  logic a,
	input  logic b,
	input  logic c,
	input  logic d,
	output logic q
);

task calculate_output;
	assign q = (a & b & ~c & ~d) | (~a & b & ~c & ~d) | (a & ~b & c & ~d) | (~a & ~b & c & ~d) | (a & b & ~c & d) | (~a & b & ~c & d) | (a & ~b & c & d) | (~a & ~b & c & d);
endtask

// Initial call to calculate the output
initial begin
	calculate_output;
end

endmodule;