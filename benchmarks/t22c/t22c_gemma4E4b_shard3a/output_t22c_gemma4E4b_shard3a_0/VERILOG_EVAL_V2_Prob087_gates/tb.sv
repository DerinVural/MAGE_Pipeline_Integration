`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic a,b,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
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
		@(negedge clk) {a,b} <= 0;
		wavedrom_start();
		@(posedge clk) {a,b} <= 0;
		@(posedge clk) {a,b} <= 1;
		@(posedge clk) {a,b} <= 2;
		@(posedge clk) {a,b} <= 3;
		@(negedge clk);
		wavedrom_stop();
		repeat(200) @(posedge clk, negedge clk)
		{a,b} <= $random;
		$finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_and;
		int errortime_out_and;
		int errors_out_or;
		int errortime_out_or;
		int errors_out_xor;
		int errortime_out_xor;
		int errors_out_nand;
		int errortime_out_nand;
		int errors_out_nor;
		int errortime_out_nor;
		int errors_out_xnor;
		int errortime_out_xnor;
		int errors_out_anotb;
		int errortime_out_anotb;
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
	logic b;
	logic out_and_ref;
	logic out_and_dut;
	logic out_or_ref;
	logic out_or_dut;
	logic out_xor_ref;
	logic out_xor_dut;
	logic out_nand_ref;
	logic out_nand_dut;
	logic out_nor_ref;
	logic out_nor_dut;
	logic out_xnor_ref;
	logic out_xnor_dut;
	logic out_anotb_ref;
	logic out_anotb_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,out_and_ref,out_and_dut,out_or_ref,out_or_dut,out_xor_ref,out_xor_dut,out_nand_ref,out_nand_dut,out_nor_ref,out_nor_dut,out_xnor_ref,out_xnor_dut,out_anotb_ref,out_anotb_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		.a,
		.b );
	RefModule good1 (
		.a,
		.b,
		.out_and(out_and_ref),
		.out_or(out_or_ref),
		.out_xor(out_xor_ref),
		.out_nand(out_nand_ref),
		.out_nor(out_nor_ref),
		.out_xnor(out_xnor_ref),
		.out_anotb(out_anotb_ref) );
	
	TopModule top_module1 (
		a,
	b,
	out_and(out_and_dut),
	out_or(out_or_dut),
	out_xor(out_xor_dut),
	out_nand(out_nand_dut),
	out_nor(out_nor_dut),
	out_xnor(out_xnor_dut),
	out_anotb(out_anotb_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	endtask	
	
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end
		else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
		end
	
		$display("Simulation finished at %0d ps", $time);
	endmodule
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref } === ( { out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref } ^ { out_and_dut, out_or_dut, out_xor_dut, out_nand_dut, out_nor_dut, out_xnor_dut, out_anotb_dut } ^ { out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
		end
		
		// Check for first mismatch and display details
		if (stats1.errors == 1) begin
			inputs_at_mismatch = {a, b};
			expected_outputs_at_mismatch = {out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref};
			actual_outputs_at_mismatch = {out_and_dut, out_or_dut, out_xor_dut, out_nand_dut, out_nor_dut, out_xnor_dut, out_anotb_dut};
			
			$display("\n======================================================================");
			$display("!!! FIRST MISMATCH DETECTED AT TIME %0d ps !!!", $time);
			$display("------------------------------------------------------------------------");
			$display("Inputs: a = %b, b = %b", a, b);
			// Displaying single bits in HEX and BIN format
			$display("Expected Outputs (Ref):  HEX=%h, BIN=%b", expected_outputs_at_mismatch, expected_outputs_at_mismatch);
			$display("Actual Outputs (DUT):    HEX=%h, BIN=%b", actual_outputs_at_mismatch, actual_outputs_at_mismatch);
			$display("======================================================================\n");
		end
		
		// Original error counting logic (kept for backward compatibility with existing counter structure)
		if (out_and_ref !== ( out_and_ref ^ out_and_dut ^ out_and_ref ))
		begin if (stats1.errors_out_and == 0) stats1.errortime_out_and = $time;
			sstats1.errors_out_and = stats1.errors_out_and+1'b1; end
		
		if (out_or_ref !== ( out_or_ref ^ out_or_dut ^ out_or_ref ))
		begin if (stats1.errors_out_or == 0) stats1.errortime_out_or = $time;
			sstats1.errors_out_or = stats1.errors_out_or+1'b1; end
		
		if (out_xor_ref !== ( out_xor_ref ^ out_xor_dut ^ out_xor_ref ))
		begin if (stats1.errors_out_xor == 0) stats1.errortime_out_xor = $time;
			sstats1.errors_out_xor = stats1.errors_out_xor+1'b1; end
		
		if (out_nand_ref !== ( out_nand_ref ^ out_nand_dut ^ out_nand_ref ))
		begin if (stats1.errors_out_nand == 0) stats1.errortime_out_nand = $time;
			sstats1.errors_out_nand = stats1.errors_out_nand+1'b1; end
		
		if (out_nor_ref !== ( out_nor_ref ^ out_nor_dut ^ out_nor_ref ))
		begin if (stats1.errors_out_nor == 0) stats1.errortime_out_nor = $time;
			sstats1.errors_out_nor = stats1.errors_out_nor+1'b1; end
		
		if (out_xnor_ref !== ( out_xnor_ref ^ out_xnor_dut ^ out_xnor_ref ))
		begin if (stats1.errors_out_xnor == 0) stats1.errortime_out_xnor = $time;
			sstats1.errors_out_xnor = stats1.errors_out_xnor+1'b1; end
		
		if (out_anotb_ref !== ( out_anotb_ref ^ out_anotb_dut ^ out_anotb_ref ))
		begin if (stats1.errors_out_anotb == 0) stats1.errortime_out_anotb = $time;
			sstats1.errors_out_anotb = stats1.errors_out_anotb+1'b1; end
		end

		// add timeout after 100K cycles
		initial begin
			h#1000000
			$display("TIMEOUT");
			$finish();
		end

endmodule


module RefModule ( 
    input a, 
    input b, 
    output out_and, 
    output out_or, 
    output out_xor, 
    output out_nand, 
    output out_nor, 
    output out_xnor, 
    output out_anotb 
);
    assign out_and = a & b;
    assign out_or = a | b;
    assign out_xor = a ^ b;
    assign out_nand = ~(a & b);
    assign out_nor = ~(a | b);
    assign out_xnor = ~(a ^ b);
    assign out_anotb = a & ~b;
endmodule


module TopModule (
    input  logic a,
    input  logic b,
    output logic out_and,
    output logic out_or,
    output logic out_xor,
    output logic out_nand,
    output logic out_nor,
    output logic out_xnor,
    output logic out_anotb
);

    // (1) out_and: a and b
    assign out_and = a & b;

    // (2) out_or: a or b
    assign out_or = a | b;

    // (3) out_xor: a xor b
    assign out_xor = a ^ b;

    // (4) out_nand: a nand b (NOT (a AND b))
    assign out_nand = ~(a & b);

    // (5) out_nor: a nor b (NOT (a OR b))
    assign out_nor = ~(a | b);

    // (6) out_xnor: a xnor b (Equivalent to a == b)
    assign out_xnor = ~(a ^ b);

    // (7) out_anotb: a and-not b (a AND NOT b)
    assign out_anotb = a & ~b;

endmodule