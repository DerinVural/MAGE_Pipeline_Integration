module TopModule (
	input logic [255:0] in,
	input logic [7:0] sel,
	public output logic out
);

	initial begin
		out = 0;
	end

	assign out = in[(sel & 255)];

endmodule