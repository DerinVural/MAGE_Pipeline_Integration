module stimulus_gen (
	input clk,
	output logic [7:0] code,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable,
	input tb_match
);

task wavedrom_start(input[511:0] title = "");

disable wand;
endtask

task wavedrom_stop;
	#1;
endtask	

initial begin
	code <= 8'h45;
	@ (negedge clk) wavedrom_start("Decode scancodes");
	@ (posedge clk) code <= 8'h45;
	@ (posedge clk) code <= 8'h03;
	@ (posedge clk) code <= 8'h46;
	@ (posedge clk) code <= 8'h16;
	@ (posedge clk) code <= 8'd26;
	@ (posedge clk) code <= 8'h1e;
	@ (posedge clk) code <= 8'h25;
	@ (posedge clk) code <= 8'h26;
	@ (posedge clk) code <= 8'h2e;
	@ (posedge clk) code <= $random;
	@ (posedge clk) code <= 8'h36;
	@ (posedge clk) code <= $random;
	@ (posedge clk) code <= 8'h3d;
	@ (posedge clk) code <= 8'h3e;
	@ (posedge clk) code <= 8'h45;
	@ (posedge clk) code <= 8'h46;
	@ (posedge clk) code <= $random;
	@ (posedge clk) code <= $random;
	@ (posedge clk) code <= $random;
	@ (posedge clk) code <= $random;
	wavedrom_stop();	
	repeat (1000) @ (posedge clk, negedge clk) begin
		code <= $urandom;
	end	
	$finish;
end

endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int errors_valid;
		int errortime_valid;
		int clocks;
	} stats;
	
	stats stats1;
	
	wire [511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk = 0;
	initial forever
		#5 clk = ~clk;
	
	logic [7:0] code;
	logic [3:0] out_ref;
	logic [3:0] out_dut;
	logic valid_ref;
	logic valid_dut;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,code,out_ref,out_dut,valid_ref,valid_dut );
	end
	
	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk(clk),
		.* ,
		.code(code)
	);
	RefModule good1 (
		.code(code),
		.out(out_ref),
		.valid(valid_ref)
	);
	TopModule top_module1 (
		.code(code),
		.out(out_dut),
		.valid(valid_dut)
	);
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	
	
	final begin
		if (stats1.errors_out) $display("Hint: Output '"out"' has "%0d" mismatches. First mismatch occurred at time "%0d".", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '"out"' has no mismatches.");
		if (stats1.errors_valid) $display("Hint: Output '"valid"' has "%0d" mismatches. First mismatch occurred at time "%0d".", stats1.errors_valid, stats1.errortime_valid);
		else $display("Hint: Output '"valid"' has no mismatches.");
		
		$display("Hint: Total mismatched samples is "%1d" out of "%1d" samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at "%0d ps", $time);
		$display("Mismatches: "%1d" in "%1d" samples", stats1.errors, stats1.clocks);
	end		
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	event tb_event;
	system task automatic verify;
		@ tb_event;
		assign tb_match = ( { out_ref, valid_ref } === ( { out_ref, valid_ref } ^ { out_dut, valid_dut } ^ { out_ref, valid_ref } ) );
	endtask		
	always @(posedge clk, negedge clk) begin		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; end
		if (valid_ref !== ( valid_ref ^ valid_dut ^ valid_ref ))
		begin if (stats1.errors_valid == 0) stats1.errortime_valid = $time;
			stats1.errors_valid = stats1.errors_valid+1'b1; end
		
		post tb_event;
	end
	
	event tb_event_done;
	initial begin
		wait (stats1.clocks > 1000000);
		post tb_event_done;
	end
	
	final begin
		@ tb_event_done;
		if (stats1.errors == 0) $display("SIMULATION PASSED");
		otherwise $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors, stats1.errortime);
	end
	
endmodule