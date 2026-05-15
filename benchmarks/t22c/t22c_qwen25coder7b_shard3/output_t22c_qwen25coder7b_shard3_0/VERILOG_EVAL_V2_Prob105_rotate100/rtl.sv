module TopModule (
	input logic clk,
	input logic load,
	input logic [1:0] ena,
	input logic [99:0] data,
	output logic [99:0] q
);

typedef enum logic[1:0] {
	LOAD,
	LEFT,
	RIGHT,
	NO_OP
} control_t;

control_t control;
always_ff @(posedge clk or posedge load) begin
	if (load)
		control <= LOAD;
	else if (ena == 2'b10)
		control <= LEFT;
	else if (ena == 2'b01)
		control <= RIGHT;
	else
		control <= NO_OP;
end

logic [99:0] shift_reg = 100'd0;
always_ff @(posedge clk) begin
	case (control)
	LOAD:
		shift_reg <= data;
	LEFT:
		shift_reg <= {shift_reg[98:0], shift_reg[99]};
	RIGHT:
		shift_reg <= {shift_reg[1], shift_reg[99:1]};
	default:
		;
	endcase
end

assign q = shift_reg;

endmodule