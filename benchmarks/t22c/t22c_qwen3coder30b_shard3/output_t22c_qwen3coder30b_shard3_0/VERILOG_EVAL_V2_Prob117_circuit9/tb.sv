`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	onput logic a,
	onput reg[511:0] wavedrom_title,
	onput reg wavedrom_enable
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

task wavedrom_start(input[511:0] title = "");
	endtask

task wavedrom_stop;
	#1;
endtask	


initial begin
	a <= 1;
	@(negedge clk) {a} <= 1;
	@(negedge clk) wavedrom_start("Unknown circuit");
		repeat(2) @(posedge clk);
		@(posedge clk) {a} <= 0;
		repeat(11) @(posedge clk);
		@(negedge clk) a <= 1;
		repeat(5) @(posedge clk, negedge clk);
		a <= 0;
		repeat(4) @(posedge clk);
	wavedrom_stop();

	repeat(200) @(posedge clk, negedge clk)
		a <= &((5)'($urandom));
	$finish;
end

endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_q;
	int errortime_q;

	int clocks;
} stats;

stats stats1;


wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic a;
logic [2:0] q_ref;
logic [2:0] q_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,a,q_ref,q_dut );
end


typedef enum logic [1:0] {
	S0,
	S1,
	S2,
	S3
} state_t;

state_t current_state, next_state;

always @(posedge clk or negedge clk) begin
	if (!clk) begin
		current_state <= S0;
	end else begin
		current_state <= next_state;
	end
end

always @(*) begin
	case(current_state)
		S0: if (a) next_state = S1;
			else next_state = S0;
		S1: if (a) next_state = S2;
			else next_state = S0;
		S2: if (a) next_state = S3;
			else next_state = S0;
		S3: if (a) next_state = S0;
			else next_state = S0;
	endcase
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		// Display first mismatch details
		if (stats1.errors == 1) begin
			$display("First mismatch at time %0d:\nInput 'a'=%b, Output 'q'=%b (expected %b)", $time, a, q_dut, q_ref);
			if ($high(q_dut) <= 64) $display("Binary: q_dut=%b, q_ref=%b", q_dut, q_ref);
		end
	end
	if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
	begin 
		if (stats1.errors_q == 0) stats1.errortime_q = $time;
		stats1.errors_q = stats1.errors_q+1'b1; 
	end

end

stimulus_gen stim1 (
	.clk,
	.* ,
	.a );
RefModule good1 (
	.clk,
	.a,
	.q(q_ref) );
	
TopModule top_module1 (
	.clk,
	.a,
	.q(q_dut) );

bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	en
endtask	

final begin
	if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
	else $display("Hint: Output '%s' has no mismatches.", "q");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	
	// Check for simulation result
	if (stats1.errors == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	end
end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule