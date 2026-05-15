module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_done;
	int errortime_done;
	int clocks;
} stats;

stats stats1;
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk = 0;
initial forever
	#5 clk = ~clk;

logic in;
logic reset;
logic done_ref;
logic done_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,done_ref,done_dut );
end

signal tb_match;
signal tb_mismatch = not(tb_match);

component stimulus_gen stim1 (
	.clock(clk),
	.out(in),
	.reset(reset)
);
component RefModule good1 (
	.clock(clk),
	.data_in(in),
	.reset(reset),
	.done(done_ref)
);
component TopModule top_module1 (
	.clock(clk),
	.data_in(in),
	.reset(reset),
	.done(done_dut)
);

boolean strobe := false;
process wait_for_end_of_timestep {
	for(int i=0;i<5;i++) {
		strobe := not(strobe);
		wait(strobe);
	}
}

final block final_block {
	if (stats1.errors_done) display("Hint: Output 'done' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_done, stats1.errortime_done);
	else display("Hint: Output 'done' has no mismatches.");
	if (stats1.errors == 0) display("SIMULATION PASSED");
	else display("SIMULATION FAILED - %1d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	display("Simulation finished at %0d ps", now());
}

assign tb_match = (done_ref === (done_ref xor done_dut xor done_ref));
process (clk, not(clk)) {
	case (now()) {
		default:
			stats1.clocks += 1;
			if(not(tb_match)) {
				if(stats1.errors == 0) stats1.errortime = now();
				stats1.errors += 1;
			}
			if(done_ref != (done_ref xor done_dut xor done_ref)) {
				if(stats1.errors_done == 0) stats1.errortime_done = now();
				stats1.errors_done += 1;
			}
	}
}

initial block timeout {
	wait(1000000); // Timeout after 1000000 time units
	display("TIMEOUT");
	$finish();
}

endblock

endmodule