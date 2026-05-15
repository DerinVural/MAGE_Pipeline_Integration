`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module TopModule (
    input  logic       clk,
    input  logic       areset,
    input  logic       train_valid,
    input  logic       train_taken,
    output logic [1:0] state
);

    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= 2'b01;
        end else if (train_valid) begin
            if (train_taken) begin
                if (state != 2'b11) state <= state + 1'b1;
            end else begin
                if (state != 2'b00) state <= state - 1'b1;
            end
        end
    end

endmodule

module stimulus_gen(
	input clk,
	output logic areset,
	output logic train_valid,
	output logic train_taken,

	input tb_match,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable,
	output int wavedrom_hide_after_time
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	reg reset;
	task reset_test(input async=0);
		bit arfail, srfail, datafail;
	
		@(posedge clk);
		@(posedge clk) reset <= 0;
		repeat(3) @(posedge clk);
	
		@(negedge clk) begin datafail = !tb_match ; reset <= 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
			srfail = !tb_match;
			reset <= 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
	end

	assign areset = reset;
	logic train_taken_r;
	assign train_taken = train_valid ? train_taken_r : 1'bx;
	
	initial begin
		@(posedge clk);
		@(posedge clk) reset <= 1;
		@(posedge clk) reset <= 0;
		train_taken_r <= 1;
		train_valid <= 1;
	
		wavedrom_start("Asynchronous reset");
			reset_test(1); // Test for asynchronous reset
		wavedrom_stop();
		@(posedge clk) reset <= 1;
		train_taken_r <= 1;
		train_valid <= 0;
		@(posedge clk) reset <= 0;

		wavedrom_start("Count up, then down");
		train_taken_r <= 1;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 0;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 0;
			@(posedge clk) train_valid <= 1;
		train_taken_r <= 0;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 0;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 1;
			@(posedge clk) train_valid <= 0;
			@(posedge clk) train_valid <= 1; 	
		wavedrom_stop();

		repeat(1000) @(posedge clk,negedge clk) 
			{train_valid, train_taken_r} <= {$urandom} ;

		#1 $finish;
	end
	

endmodule

module RefModule (
	input clk,
	input areset,
	input train_valid,
	input train_taken,
	output logic [1:0] state
);
	logic [1:0] count;
	always_ff @(posedge clk or posedge areset) begin
		if (areset) count <= 2'b01;
		else if (train_valid) begin
			if (train_taken) begin
				if (count != 2'b11) count <= count + 1'b1;
			end else begin
				if (count != 2'b00) count <= count - 1'b1;
			end
		end
	end;
	assign state = count;
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_state;
		int errortime_state;

		int clocks;
	} stats;
	
	stats stats1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic areset;
	logic train_valid;
	logic train_taken;
	logic [1:0] state_ref;
	logic [1:0] state_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,train_valid,train_taken,state_ref,state_dut );
	end

	wire tb_match; // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.areset,
		.train_valid,
		.train_taken );
	RefModule good1 (
		.clk,
		.areset,
		.train_valid,
		.train_taken,
		.state(state_ref) );
		
	TopModule top_module1 (
		.clk,
		.areset,
		.train_valid,
		.train_taken,
		.state(state_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	

	assign tb_match = ( { state_ref } === ( { state_ref } ^ { state_dut } ^ { state_ref } ) );

	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (state_ref !== ( state_ref ^ state_dut ^ state_ref ))
		begin 
			if (stats1.errors_state == 0) stats1.errortime_state = $time;
			stats1.errors_state = stats1.errors_state+1'b1; 
		end
	end

	// Mismatch Display Logic
	always @(posedge clk) begin
		if (!tb_match && stats1.errors == 1) begin
			$display("Mismatch detected!");
			$display("Time: %0t", $time);
			$display("Inputs: areset=%b, train_valid=%b, train_taken=%b", areset, train_valid, train_taken);
			$display("Outputs: state_dut=%h (%b), state_ref=%h (%b)", state_dut, state_dut, state_ref, state_ref);
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

	if (stats1.errors_state) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "state", stats1.errors_state, stats1.errortime_state);
	else $display("Hint: Output '%s' has no mismatches.", "state");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule