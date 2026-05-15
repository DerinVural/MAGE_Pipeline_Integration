module TopModule (
	input logic [3:0] in,
	output logic [1:0] pos
);

	logic [1:0] pos_reg;
	assign pos = pos_reg;

	always @(*) begin
		pos_reg = 2'b00;
		for (int i = 3; i >= 0; i--) begin
			if (in[i]) begin
				pos_reg = i;
				return;
			end
		end
	end

endmodule;