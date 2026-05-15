`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [4:0] a,b,c,d,e,f,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		wavedrom_start("");
		@(posedge clk) {a,b,c,d,e,f} <= '0;
		@(posedge clk) {a,b,c,d,e,f} <= 1;
		@(posedge clk) {a,b,c,d,e,f} <= 2;
		@(posedge clk) {a,b,c,d,e,f} <= 4;
		@(posedge clk) {a,b,c,d,e,f} <= 8;
		@(posedge clk) {a,b,c,d,e,f} <= 'h10;
		@(posedge clk) {a,b,c,d,e,f} <= 'h20;
		@(posedge clk) {a,b,c,d,e,f} <= 'h40;
		@(posedge clk) {a,b,c,d,e,f} <= 'h80;
		@(posedge clk) {a,b,c,d,e,f} <= 'h100;
		@(posedge clk) {a,b,c,d,e,f} <= 'h200;
		@(posedge clk) {a,b,c,d,e,f} <= 'h400;
		@(posedge clk) {a,b,c,d,e,f} <= {5'h1f, 5'h0, 5'h1f, 5'h0, 5'h1f, 5'h0};
		@(negedge clk);
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			{a,b,c,d,e,f} <= $random;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_w;
		int errortime_w;
		int errors_x;
		int errortime_x;
		int errors_y;
		int errortime_y;
		int errors_z;
		int errortime_z;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [4:0] a;
	logic [4:0] b;
	logic [4:0] c;
	logic [4:0] d;
	logic [4:0] e;
	logic [4:0] f;
	logic [7:0] w_ref;
	logic [7:0] w_dut;
	logic [7:0] x_ref;
	logic [7:0] x_dut;
	logic [7:0] y_ref;
	logic [7:0] y_dut;
	logic [7:0] z_ref;
	logic [7:0] z_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,e,f,w_ref,w_dut,x_ref,x_dut,y_ref,y_dut,z_ref,z_dut );
	end

	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b,
		.c,
		.d,
		.e,
		.f );
	RefModule good1 (
		.a,
		.b,
		.c,
		.d,
		.e,
		.f,
		.w(w_ref),
		.x(x_ref),
		.y(y_ref),
		.z(z_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.c,
		.d,
		.e,
		.f,
		.w(w_dut),
		.x(x_dut),
		.y(y_dut),
		.z(z_dut) );


	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	// Helper for formatted display
	function string fmt(logic [7:0] val);
		return $sformatf("HEX: 'h%h, BIN: 'b%b", val, val);
	endfunction

	// Mismatch detection display
	initial begin
		wait(tb_mismatch);
		$display("FIRST MISMATCH DETECTED AT TIME %0t", $time);
		$display("Inputs: a=%h, b=%h, c=%h, d=%h, e=%h, f=%h", a, b, c, d, e, f);
		$display("Outputs: w_ref=%s, w_dut=%s", fmt(w_ref), fmt(w_dut));
		$display("         x_ref=%s, x_dut=%s", fmt(x_ref), fmt(x_dut));
		$display("         y_ref=%s, y_dut=%s", fmt(y_ref), fmt(y_dut));
		$display("         z_ref=%s, z_dut=%s", fmt(z_ref), fmt(z_dut));
	end

	final begin
		if (stats1.errors_w) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "w", stats1.errors_w, stats1.errortime_w);
		else $display("Hint: Output '%s' has no mismatches.", "w");
		if (stats1.errors_x) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "x", stats1.errors_x, stats1.errortime_x);
		else $display("Hint: Output '%s' has no mismatches.", "x");
		if (stats1.errors_y) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "y", stats1.errors_y, stats1.errortime_y);
		else $display("Hint: Output '%s' has no mismatches.", "y");
		if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
		else $display("Hint: Output '%s' has no mismatches.", "z");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { w_ref, x_ref, y_ref, z_ref } === ( { w_ref, x_ref, y_ref, z_ref } ^ { w_dut, x_dut, y_dut, z_dut } ^ { w_ref, x_ref, y_ref, z_ref } ) );
	// Use explicit sensitivity list here. Avoid @(*)
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (w_ref !== ( w_ref ^ w_dut ^ w_ref ))
		begin if (stats1.errors_w == 0) stats1.errortime_w = $time;
			stats1.errors_w = stats1.errors_w+1'b1; end
		if (x_ref !== ( x_ref ^ x_dut ^ x_ref ))
		begin if (stats1.errors_x == 0) stats1.errortime_x = $time;
			stats1.errors_x = stats1.errors_x+1'b1; end
		if (y_ref !== ( y_ref ^ y_dut ^ y_ref ))
		begin if (stats1.errors_y == 0) stats1.errortime_y = $time;
			stats1.errors_y = stats1.errors_y+1'b1; end
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
			stats1.errors_z = stats1.errors_z+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule