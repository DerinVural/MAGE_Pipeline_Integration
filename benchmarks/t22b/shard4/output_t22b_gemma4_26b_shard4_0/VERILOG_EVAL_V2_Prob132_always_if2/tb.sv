`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic cpu_overheated, arrived, gas_tank_empty,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	logic [2:0] s = 3'b010;
	assign {cpu_overheated, arrived, gas_tank_empty} = s;

	initial begin
		@(negedge clk) wavedrom_start("");
		@(posedge clk) s <= 3'b010;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b001;
		@(posedge clk) s <= 3'b000;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b110;
		@(posedge clk) s <= 3'b111;
		@(posedge clk) s <= 3'b111;
		@(posedge clk) s <= 3'b111;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			s <= $urandom;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_shut_off_computer;
		int errortime_shut_off_computer;
		int errors_keep_driving;
		int errortime_keep_driving;

		int clocks;
	} stats;
	
	stats stats1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic cpu_overheated;
	logic arrived;
	logic gas_tank_empty;
	logic shut_off_computer_ref;
	logic shut_off_computer_dut;
	logic keep_driving_ref;
	logic keep_driving_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, cpu_overheated, arrived, gas_tank_empty, shut_off_computer_ref, shut_off_computer_dut, keep_driving_ref, keep_driving_dut );
	end

	wire tb_match;    // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.cpu_overheated,
		.arrived,
		.gas_tank_empty );
	RefModule good1 (
		.cpu_overheated,
		.arrived,
		.gas_tank_empty,
		.shut_off_computer(shut_off_computer_ref),
		.keep_driving(keep_driving_ref) );
		
	TopModule top_module1 (
		.cpu_overheated,
		.arrived,
		.gas_tank_empty,
		.shut_off_computer(shut_off_computer_dut),
		.keep_driving(keep_driving_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;
			@(strobe);
		end
	endtask	

	assign tb_match = ( { shut_off_computer_ref, keep_driving_ref } === ( { shut_off_computer_ref, keep_driving_ref } ^ { shut_off_computer_ref, keep_driving_ref } ^ { shut_off_computer_dut, keep_driving_dut } ^ { shut_off_computer_ref, keep_driving_ref } ) );

	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;

			// Display first mismatch details
			if (stats1.errors == 1) begin
				$display("FIRST MISMATCH DETECTED AT TIME %0t", $time);
				$display("Inputs: cpu_overheated=%b, arrived=%b, gas_tank_empty=%b", cpu_overheated, arrived, gas_tank_empty);
				$display("Expected Outputs: shut_off_computer=%b, keep_driving=%b", shut_off_computer_ref, keep_driving_ref);
				$display("Actual Outputs:   shut_off_computer=%b, keep_driving=%b", shut_off_computer_dut, keep_driving_dut);
			end
		end

		if (shut_off_computer_ref !== ( shut_off_computer_ref ^ shut_off_computer_dut ^ shut_off_computer_ref ))
		begin 
			if (stats1.errors_shut_off_computer == 0) stats1.errortime_shut_off_computer = $time;
			stats1.errors_shut_off_computer = stats1.errors_shut_off_computer + 1;
		end

		if (keep_driving_ref !== ( keep_driving_ref ^ keep_driving_dut ^ keep_driving_ref ))
		begin 
			if (stats1.errors_keep_driving == 0) stats1.errortime_keep_driving = $time;
			stats1.errors_keep_driving = stats1.errors_keep_driving + 1;
		end
	end

   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end

		if (stats1.errors_shut_off_computer) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "shut_off_computer", stats1.errors_shut_off_computer, stats1.errortime_shut_off_computer);
		else $display("Hint: Output '%s' has no mismatches.", "shut_off_computer");
		if (stats1.errors_keep_driving) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "keep_driving", stats1.errors_keep_driving, stats1.errortime_keep_driving);
		else $display("Hint: Output '%s' has no mismatches.", "keep_driving");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule