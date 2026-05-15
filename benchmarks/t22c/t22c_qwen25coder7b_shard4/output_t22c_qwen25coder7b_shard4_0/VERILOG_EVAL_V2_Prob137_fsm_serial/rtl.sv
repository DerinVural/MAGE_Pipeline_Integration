module TopModule(
	input logic clk,
	input logic reset,
	input logic in,
	output logic done
);
	parameter START_BIT = 1'b0;
	parameter STOP_BIT = 1'b1;

	// Define states
	localparam IDLE = 2'b00;
	localparam RECV_DATA = 2'b01;
	localparam CHECK_STOP = 2'b10;

	// State variables
	logic [1:0] state;
	logic [1:0] state_next;

	// Register to store received data
	logic [7:0] data_reg;
	logic [2:0] bit_count;

	// Internal flags
	logic start_bit_received;
	logic stop_bit_correct;

	// Sequential logic
	always @(posedge clk or posedge reset) begin
		if (reset)
		begin
			state <= IDLE;
			data_reg <= 8'b0;
			bit_count <= 3'b0;
			start_bit_received <= 1'b0;
			stop_bit_correct <= 1'b0;
			done <= 1'b0;
		end
		else
		begin
			state <= state_next;
			case(state)
				IDLE:
					if (in == START_BIT && !start_bit_received)
					begin
						state_next <= RECV_DATA;
						start_bit_received <= 1'b1;
					end
				RECV_DATA:
					if (bit_count < 3'b100)
					begin
						data_reg <= {data_reg[6:0], in};
						bit_count <= bit_count + 1;
					end
					else
					begin
						state_next <= CHECK_STOP;
					end
				CHECK_STOP:
					if (in == STOP_BIT)
					begin
						stop_bit_correct <= 1'b1;
						state_next <= IDLE;
						done <= 1'b1;
					end
					else
						state_next <= CHECK_STOP;
				endcase
		end
	end

	// Combinational logic for next state and done signal
	always @(*) begin
		start_bit_received <= 1'b0;
		stop_bit_correct <= 1'b0;
		case(state)
			IDLE:
				if (in == START_BIT)
					start_bit_received <= 1'b1;
			RECV_DATA:
				if (bit_count < 3'b100 && bit_count >= 3'b000)
					data_reg <= {data_reg[6:0], in};
			CHECK_STOP:
				if (in == STOP_BIT)
					stop_bit_correct <= 1'b1;
		endcase
	end

endmodule