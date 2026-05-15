module TopModule (
	input logic mode,
	input logic too_cold,
	input logic too_hot,
	input logic fan_on,
	output logic heater,
	output logic aircon,
	output logic fan,
	input logic reset
);

	// Initialize outputs to known values
	initial begin
		heater = 0;
		aircon = 0;
		fan = 0;
	end

	// Combinational logic
	always @(*) begin
		if (reset)
		begin
			heater = 0;
			aircon = 0;
			fan = 0;
		end
		else
		begin
			if (mode) begin // Heating mode
				if (too_cold)
				begin
					heater = 1;
					aircon = 0;
					fan = 1;
				end
				else
				begin
					heater = 0;
					aircon = 0;
					fan = 0;
				end
			end else begin // Cooling mode
				if (too_hot)
				begin
					aircon = 1;
					fan = 1;
				end
				else
				begin
					aircon = 0;
					fan = 0;
				end
			end
			// User-requested fan override
			if (fan_on)
				fan = 1;
		end
	end

endmodule;