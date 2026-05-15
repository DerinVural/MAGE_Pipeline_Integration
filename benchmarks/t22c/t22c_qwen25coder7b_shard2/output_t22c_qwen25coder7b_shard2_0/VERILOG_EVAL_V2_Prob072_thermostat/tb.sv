module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_heater;
	int errortime_heater;
	int errors_aircon;
	int errortime_aircon;
	int errors_fan;
	int errortime_fan;

	int clocks;
} stats;()

stats stats1;

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic mode;
logic too_cold;
logic too_hot;
logic fan_on;
logic heater_ref;
logic heater_dut;
logic aircon_ref;
logic aircon_dut;
logic fan_ref;
logic fan_dut;

initial begin 	$dumpfile("wave.vcd");	$dumpvars(1, stim1.clk, tb_mismatch ,mode,too_cold,too_hot,fan_on,heater_ref,heater_dut,aircon_ref,aircon_dut,fan_ref,fan_dut );
end

display "Starting simulation...";

wire tb_match; w
ire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.mode,
	.too_cold,
	.too_hot,
	.fan_on
);
RefModule good1 (
	.mode,
	.too_cold,
	.too_hot,
	.fan_on,
	.heater(heater_ref),
	.aircon(aircon_ref),
	.fan(fan_ref) );

TopModule top_module1 (
	.mode,
	.too_cold,
	.too_hot,
	.fan_on,
	.heater(heater_dut),
	.aircon(aircon_dut),
	.fan(fan_dut) );

bit strobe = 0;
task wait_for_end_of_timestep;repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	

final begin	display "Simulation completed.";
	if (stats1.errors_heater) display "Hint: Output 'heater' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_heater, stats1.errortime_heater;
	else display "Hint: Output 'heater' has no mismatches.";
	if (stats1.errors_aircon) display "Hint: Output 'aircon' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_aircon, stats1.errortime_aircon;
	else display "Hint: Output 'aircon' has no mismatches.";
	if (stats1.errors_fan) display "Hint: Output 'fan' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_fan, stats1.errortime_fan;
	else display "Hint: Output 'fan' has no mismatches.";
	display "Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks;
	display "Simulation finished at %0d ps", $time;
	display "Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks;
	if (stats1.errors == 0) display "SIMULATION PASSED";
	else display "SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime;
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { heater_ref, aircon_ref, fan_ref } === ( { heater_ref, aircon_ref, fan_ref } ^ { heater_dut, aircon_dut, fan_dut } ^ { heater_ref, aircon_ref, fan_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin
	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (heater_ref !== ( heater_ref ^ heater_dut ^ heater_ref ))
	begin if (stats1.errors_heater == 0) stats1.errortime_heater = $time;
		stats1.errors_heater = stats1.errors_heater+1'b1; end
	if (aircon_ref !== ( aircon_ref ^ aircon_dut ^ aircon_ref ))
	begin if (stats1.errors_aircon == 0) stats1.errortime_aircon = $time;
		stats1.errors_aircon = stats1.errors_aircon+1'b1; end
	if (fan_ref !== ( fan_ref ^ fan_dut ^ fan_ref ))
	begin if (stats1.errors_fan == 0) stats1.errortime_fan = $time;
		stats1.errors_fan = stats1.errors_fan+1'b1; end
	
display "Time: %0d ps - Errors: %0d, Heater Errors: %0d, Aircon Errors: %0d, Fan Errors: %0d", $time, stats1.errors, stats1.errors_heater, stats1.errors_aircon, stats1.errors_fan;
end

	// add timeout after 100K cycles
	initial begin
	  #1000000
	  display "TIMEOUT";
	  $finish();
	end

endmodule