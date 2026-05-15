module TopModule (
	logic clk,
	logic reset,
	logic ena,
	logic pm,
	logic [7:0] hh,
	logic [7:0] mm,
	logic [7:0] ss
);

	// Internal registers for counters
	logic [7:0] reg_hh;
	logic [7:0] reg_mm;
	logic [7:0] reg_ss;

	// Initialize counters to zero on power-on reset
	initial begin
		reg_hh = 8'd0;
		reg_mm = 8'd0;
		reg_ss = 8'd0;
	end

	// Sequential logic for counting
	always @(posedge clk) begin
		if (reset) begin
			reg_hh <= 8'd0;
			reg_mm <= 8'd0;
			reg_ss <= 8'd0;
		end else if (ena) begin
			if (reg_ss == 8'd59) begin
				reg_ss <= 8'd0;
				if (reg_mm == 8'd59) begin
					reg_mm <= 8'd0;
					if (reg_hh == 8'd12) begin
						pm <= ~pm;
						reg_hh <= 8'd1;
					end else if (reg_hh == 8'd23) begin
						reg_hh <= 8'd1;
					end else begin
						reg_hh <= reg_hh + 8'd1;
					end
				end else begin
					reg_mm <= reg_mm + 8'd1;
				end
			end else begin
				reg_ss <= reg_ss + 8'd1;
			end
		end
	end

	// Assign output values
	hh <= reg_hh;
	mm <= reg_mm;
	ss <= reg_ss;

endmodule