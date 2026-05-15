`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic areset,
	output logic predict_valid,
	output predict_taken,
	output logic train_mispredicted,
	output train_taken,
	output logic [31:0] train_history,
	input tb_match,
	output reg [511:0] wavedrom_title,
	output reg wavedrom_enable,
	output int wavedrom_hide_after_time
);

	task wavedrom_start(input [511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	reg reset;
	task reset_test(input async = 0);
		bit arfail, srfail, datafail;
	
		@(posedge clk);
		@(posedge clk) reset <= 0;
		repeat(3) @(posedge clk);
	
		@(negedge clk) begin datafail = !tb_match; reset <= 1; end
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
	logic predict_taken_r;
	assign predict_taken = predict_valid ? predict_taken_r : 1'bx;
	
	logic train_taken_r;
	logic [31:0] train_history_r;
	assign train_taken = train_mispredicted ? train_taken_r : 1'bx;
	assign train_history = train_mispredicted ? train_history_r : 32'hx;
	
	initial begin
		@(posedge clk) reset <= 1;
		@(posedge clk) reset <= 0;
		predict_taken_r <= 1;
		predict_valid <= 1;
		train_mispredicted <= 0;
		train_history_r <= 32'h5;
		train_taken_r <= 1;
	
		wavedrom_start("Asynchronous reset");
		reset_test(1);
		wavedrom_stop();
		@(posedge clk) reset <= 1;
		predict_valid <= 0;

		wavedrom_start("Predictions: Shift in");
		repeat(2) @(posedge clk) {predict_valid, predict_taken_r} <= {$urandom};
		reset <= 0;
		predict_valid <= 1;
		repeat(6) @(posedge clk) {predict_taken_r} <= {$urandom};
		predict_valid <= 0;
		repeat(3) @(posedge clk) {predict_taken_r} <= {$urandom};
		predict_valid <= 1;
		train_mispredicted <= 1;
		@(posedge clk) train_mispredicted <= 0;
		repeat(6) @(posedge clk) {predict_taken_r} <= {$urandom};
		wavedrom_stop();

		repeat(2000) @(posedge clk, negedge clk) begin
			{predict_valid, predict_taken_r, train_taken_r} <= {$urandom};
			train_history_r <= $urandom;
			train_mispredicted <= !($urandom_range(0,31));
		end

		#1 $finish;
	end
	
	endmodule

module RefModule (
	input clk,
	input areset,
	input predict_valid,
	input predict_taken,
	input train_mispredicted,
	input train_taken,
	input [31:0] train_history,
	output logic [31:0] predict_history
);
	logic [31:0] hist;
	always_ff @(posedge clk or posedge areset) begin
		if (areset) hist <= 32'h0;
		else begin
			if (train_mispredicted) hist <= {train_history[30:0], train_taken};
			else if (predict_valid) hist <= {hist[30:0], predict_taken};
		end
	end
	assign predict_history = hist;
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_predict_history;
		int errortime_predict_history;
		int clocks;
	} stats;
	
	stats stats1;
	
	wire [511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever #5 clk = ~clk;

	logic areset;
	logic predict_valid;
	logic predict_taken;
	logic train_mispredicted;
	logic train_taken;
	logic [31:0] train_history;
	logic [31:0] predict_history_ref;
	logic [31:0] predict_history_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, clk, areset, predict_valid, predict_taken, train_mispredicted, train_taken, train_history, predict_history_ref, predict_history_dut);
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.*,
		.areset,
		.predict_valid,
		.predict_taken,
		.train_mispredicted,
		.train_taken,
		.train_history
	);

	RefModule good1 (
		.clk,
		.areset,
		.predict_valid,
		.predict_taken,
		.train_mispredicted,
		.train_taken,
		.train_history,
		.predict_history(predict_history_ref)
	);
		
	TopModule top_module1 (
		.clk,
		.areset,
		.predict_valid,
		.predict_taken,
		.train_mispredicted,
		.train_taken,
		.train_history,
		.predict_history(predict_history_dut)
	);

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;
			@(strobe);
		end;
	endtask	

	assign tb_match = ( { predict_history_ref } === ( { predict_history_ref } ^ { predict_history_dut } ^ { predict_history_ref } ) );

	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (predict_history_ref !== ( predict_history_ref ^ predict_history_dut ^ predict_history_ref )) begin
			if (stats1.errors_predict_history == 0) stats1.errortime_predict_history = $time;
			stats1.errors_predict_history = stats1.errors_predict_history + 1'b1;
		end
	end

	// First Mismatch Display Logic
	always @(posedge clk) begin
		if (!tb_match && stats1.errors == 1 && stats1.errortime == $time) begin
			$display("FIRST MISMATCH DETECTED AT TIME %0t:", $time);
			$display("Inputs: clk=%b, areset=%b, predict_valid=%b, predict_taken=%b, train_mispredicted=%b, train_taken=%b, train_history=0x%h (%b)", 
				clk, areset, predict_valid, predict_taken, train_mispredicted, train_taken, train_history, train_history);
			$display("Outputs: predict_history_dut=0x%h (%b), predict_history_ref=0x%h (%b)", 
				predict_history_dut, predict_history_dut, predict_history_ref, predict_history_ref);
		end
	end

	initial begin 
		#1000000;
		$display("TIMEOUT");
		$finish();
	end

	final begin
		if (stats1.errors_predict_history) 
			$display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "predict_history", stats1.errors_predict_history, stats1.errortime_predict_history);
		if (stats1.errors_predict_history == 0) 
			$display("Hint: Output '%s' has no mismatches.", "predict_history");

		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
		
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule