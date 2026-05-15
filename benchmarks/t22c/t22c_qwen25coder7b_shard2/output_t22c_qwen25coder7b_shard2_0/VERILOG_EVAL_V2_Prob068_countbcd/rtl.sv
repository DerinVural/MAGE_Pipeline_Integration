module TopModule (
	input logic clk,
	input logic reset,
	output logic [2:0] ena,
	output logic [15:0] q
);
	parameter WIDTH = 4;
	parameter DEPTH = 4;

	logic [WIDTH-1:0] bcd_counter;
	logic [DEPTH-1:0] ena_logic;
	logic [15:0] q_reg;

	initial begin
		bcd_counter = 0;
		ena_logic = 3'b000;
		q_reg = 16'b0000_0000_0000_0000;
	end

	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			bcd_counter <= 0;
			ena_logic <= 3'b000;
			q_reg <= 16'b0000_0000_0000_0000;
		end else begin
			bcd_counter <= bcd_counter + 1;
			if (bcd_counter[3] == WIDTH'h9) begin
				bcd_counter <= bcd_counter + 1;
				ena_logic[0] <= 1'b1;
			end else begin
				bcd_counter <= bcd_counter;
				ena_logic[0] <= 1'b0;
			end
			if (bcd_counter[7:4] == WIDTH'h9) begin
				bcd_counter <= bcd_counter + 1;
				ena_logic[1] <= 1'b1;
			end else begin
				bcd_counter <= bcd_counter;
				ena_logic[1] <= 1'b0;
			end
			if (bcd_counter[11:8] == WIDTH'h9) begin
				bcd_counter <= bcd_counter + 1;
				ena_logic[2] <= 1'b1;
			end else begin
				bcd_counter <= bcd_counter;
				ena_logic[2] <= 1'b0;
			end
			ena <= {ena_logic[2], ena_logic[1], ena_logic[0]};
			q_reg <= {bcd_counter[15:12], bcd_counter[11:8], bcd_counter[7:4], bcd_counter[3:0]};
		end
	end

	assign q = q_reg;

endmodule;