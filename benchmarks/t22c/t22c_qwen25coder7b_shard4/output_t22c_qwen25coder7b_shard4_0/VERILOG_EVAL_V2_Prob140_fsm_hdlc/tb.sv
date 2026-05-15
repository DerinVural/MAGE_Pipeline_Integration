module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_disc;
		int errortime_disc;
		int errors_flag;
		int errortime_flag;
		int errors_err;
		int errortime_err;
		int clocks;
	} stats;
	stats stats1;
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	reg clk=0;
	initial forever
		#5 clk = ~clk;
	display("Simulation started");
	logic reset;
	logic in;
	logic disc_ref;
	logic disc_dut;
	logic flag_ref;
	logic flag_dut;
	logic err_ref;
	logic err_dut;
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,in,disc_ref,disc_dut,flag_ref,flag_dut,err_ref,err_dut );
	end
	wire tb_match;    // Verification
	wire tb_mismatch = ~tb_match;
	stimulus_gen stim1 (
		.clk,
		.* ,
		.reset,
		.in
	);
	RefModule good1 (
		.clk,
		.reset,
		.in,
		.disc(disc_ref),
		.flag(flag_ref),
		.err(err_ref) );
	TopModule_top_module1 (
		.clk,
		.reset,
		.in,
		.disc(disc_dut),
		.flag(flag_dut),
		.err(err_dut) );
	bit strobe = 0;
	task wait_for_end_of_timestep;		repeat(5) begin			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask		event timeout_event;
	event mismatch_event;
	event pass_event;
	event fail_event;
		initial begin
			#1000000
			eventually timeout_event;
		end
		always @(posedge clk) begin
			if (stats1.errors > 0)
				eventually mismatch_event;
			else
				eventually pass_event;
		end
		initial begin
			wait (timeout_event);
			$display("TIMEOUT");
			$finish;
		end
		initial begin
			wait (mismatch_event);
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$finish;
		end
		initial begin
			wait (pass_event);
			$display("SIMULATION PASSED");
			$finish;
		end
	endmodule