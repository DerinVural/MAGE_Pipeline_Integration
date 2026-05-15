module TopModule (
	logic clk,
	logic reset,
	logic [2:0] s,
	output logic fr2,
	output logic fr1,
	output logic fr0,
	output logic dfr
);

	logic [2:0] prev_s;
	logic fr2_int;
	logic fr1_int;
	logic fr0_int;
	logic dfr_int;

	initial begin
		prev_s = 3'b111;
		fr2_int = 0;
		fr1_int = 0;
		fr0_int = 0;
		dfr_int = 0;
	end

	always @(posedge clk) begin
		if (reset) begin
			prev_s <= 3'b111;
			fr2_int <= 0;
			fr1_int <= 0;
			fr0_int <= 0;
			dfr_int <= 0;
		end else begin
			prev_s <= s;
		end
	end

	always @(*) begin
		case ({prev_s, s})
			3'b000: begin fr2_int = 0; fr1_int = 0; fr0_int = 0; dfr_int = 0; end
			3'b001: begin fr2_int = 1; fr1_int = 0; fr0_int = 0; dfr_int = 0; end
			3'b010: begin fr2_int = 0; fr1_int = 1; fr0_int = 0; dfr_int = 0; end
			3'b011: begin fr2_int = 0; fr1_int = 1; fr0_int = 1; dfr_int = 0; end
			3'b100: begin fr2_int = 0; fr1_int = 0; fr0_int = 1; dfr_int = 1; end
			3'b101: begin fr2_int = 0; fr1_int = 0; fr0_int = 1; dfr_int = 1; end
			3'b110: begin fr2_int = 0; fr1_int = 0; fr0_int = 1; dfr_int = 1; end
			3'b111: begin fr2_int = 0; fr1_int = 0; fr0_int = 0; dfr_int = 0; end
			default: begin fr2_int = 0; fr1_int = 0; fr0_int = 0; dfr_int = 0; end
		endcase
	end

	assign fr2 = fr2_int;
	assign fr1 = fr1_int;
	assign fr0 = fr0_int;
	assign dfr = dfr_int;

endmodule