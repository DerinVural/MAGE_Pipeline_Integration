// Testbench code starts
`timescale 1ps/1ps
module tb();
	doubletime = 0;
	reg clk;
	logic one_ref;
	logic one_dut;
	wire tb_match;
	signals for error display
	// Stimulus generation
	stimulus_gen stim1 (.*);
	RefModule ref_inst (.*);
	TopModule dut (.*);

	// Error tracking
	always @(posedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (one_ref !== (one_ref ^ one_dut ^ one_ref)) begin
			if (stats1.errors_one == 0) stats1.errortime_one = $time;
			stats1.errors_one++;
		end
	end

	final block for display
endmodule
// End of testbench