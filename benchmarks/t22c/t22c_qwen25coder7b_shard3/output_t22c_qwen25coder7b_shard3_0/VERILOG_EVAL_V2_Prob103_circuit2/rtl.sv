module TopModule (
	input logic a,
	input logic b,
	input logic c,
	input logic d,
	output logic q
);

	// Derive the logic expression from the waveform patterns
	assign q = (a & b & d) | (a & b & c & d) | (b & c & d) | (a & d);

endmodule;