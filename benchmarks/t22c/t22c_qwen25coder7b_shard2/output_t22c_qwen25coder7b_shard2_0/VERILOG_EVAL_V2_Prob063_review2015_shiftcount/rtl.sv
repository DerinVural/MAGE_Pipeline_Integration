module TopModule (
	input logic clk,
	input logic shift_ena,
	input logic count_ena,
	input logic data,
	input logic reset,
	output logic [3:0] q
);

logic [3:0] shift_reg;
logic [2:0] count;
logic state, state_next;

initial begin
	shift_reg = 4'b0000;
	count = 3'd7;
	state = 1'b0;
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		shift_reg <= 4'b0000;
		count <= 3'd7;
		state <= 1'b0;
	end else begin
		case (state)
			1'b0: begin
				if (shift_ena)
					state_next = 1'b1;
				else if (count_ena && count != 0)
					state_next = 1'b10;
				else
					state_next = 1'b0;
			end
			1'b1: begin
				shift_reg <= {data, shift_reg[3:1]};
				state_next = 1'b0;
			end
			1'b10: begin
				count--;
				if (count == 0)
					state_next = 1'b0;
				else
					state_next = 1'b10;
			end
			default: state_next = 1'b0;
		endcase
	end
end

always @(*) begin
	q = shift_reg;
end

endmodule