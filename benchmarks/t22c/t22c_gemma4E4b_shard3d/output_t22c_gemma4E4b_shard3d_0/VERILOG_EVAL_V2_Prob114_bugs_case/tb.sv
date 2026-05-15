`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic [7:0] code,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask	

	
	initial begin
		code <= 8'h45;
		@(negedge clk) wavedrom_start("Decode scancodes");
			@(posedge clk) code <= 8'h45;
			@(posedge clk) code <= 8'h03;
			@(posedge clk) code <= 8'h46;
			@(posedge clk) code <= 8'h16;
			@(posedge clk) code <= 8'd26;
			@(posedge clk) code <= 8'h1e;
			@(posedge clk) code <= 8'h25;
			@(posedge clk) code <= 8'h26;
			@(posedge clk) code <= 8'h2e;
			@(posedge clk) code <= $random;
			@(posedge clk) code <= 8'h36;
			@(posedge clk) code <= $random;
			@(posedge clk) code <= 8'h3d;
			@(posedge clk) code <= 8'h3e;
			@(posedge clk) code <= 8'h45;
			@(posedge clk) code <= 8'h46;
			@(posedge clk) code <= $random;
			@(posedge clk) code <= $random;
			@(posedge clk) code <= $random;
			@(posedge clk) code <= $random;
		wavedrom_stop();
		
		repeat(1000) @(posedge clk, negedge clk) begin
			code <= $urandom;
		end		
		$finish;
	end
	
d
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
		// Snapshot variables for first mismatch display
		logic [7:0] code_snapshot;
		logic [3:0] out_ref_snapshot;
		logic [3:0] out_dut_snapshot;
		logic valid_ref_snapshot;
		logic valid_dut_snapshot;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic [7:0] code;
	logic [3:0] out_ref;
	logic [3:0] out_dut;
	logic valid_ref;
	logic valid_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen.clk, tb_mismatch ,code,out_ref,out_dut,valid_ref,valid_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.code );
	RefModule good1 (
		.code,
		out(out_ref),
		.valid(valid_ref) );
	
	TopModule top_module1 (
		.code,
		out(out_dut),
		.valid(valid_dut) );


	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end		
		endtask

	
		// --- New Display Logic for Mismatch Snapshot --- 
		initial begin
			// Initialize snapshot variables
			code_snapshot = 8'h00;
			out_ref_snapshot = 4'h0;
			out_dut_snapshot = 4'h0;
			valid_ref_snapshot = 1'b0;
			valid_dut_snapshot = 1'b0;
			end
		
		// Monitor for the FIRST mismatch
		forever begin
			@(posedge clk);
			if (!tb_match && stats1.errors == 0) begin
				$display("\n============================================================");
				$display("*** FIRST MISMATCH DETECTED AT TIME %0d ps ***", $time);
				$display("============================================================");
				$display("Input Signals (code): HEX = %h, BIN = %b", code, code);
				$display("Expected Output Signals (ref): HEX = %h, BIN = %b", out_ref, out_ref);
				$display("DUT Output Signals: HEX = %h, BIN = %b", out_dut, out_dut);
				$display("Expected Valid: %b | DUT Valid: %b", valid_ref, valid_dut);
				end
			end
		end
		
		// Store snapshot upon first detection
			if (!tb_match && stats1.errors == 0) begin
				code_snapshot = code;
				out_ref_snapshot = out_ref;
			out_dut_snapshot = out_dut;
			valid_ref_snapshot = valid_ref;
			valid_dut_snapshot = valid_dut;
			end
		
		// Update snapshot data on every clock edge to keep it current if needed, though only the first is truly captured.
			code_snapshot = code;
			out_ref_snapshot = out_ref;
			out_dut_snapshot = out_dut;
			valid_ref_snapshot = valid_ref;
			valid_dut_snapshot = valid_dut;
		end
		
		end

		
		
		// Original final block replaced for new reporting requirements
		final begin
			if (stats1.errors == 0) begin
				$display("\n*****************************************");
				$display("SIMULATION PASSED");
				$display("*****************************************");
			end else begin
				$display("\n============================================================");
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
				$display("============================================================");
				$display("--- Details at First Mismatch ---");
				$display("Input Signals (code): HEX = %h, BIN = %b", code_snapshot, code_snapshot);
				$display("Expected Output Signals (ref): HEX = %h, BIN = %b", out_ref_snapshot, out_ref_snapshot);
				$display("DUT Output Signals: HEX = %h, BIN = %b", out_dut_snapshot, out_dut_snapshot);
				$display("Expected Valid: %b | DUT Valid: %b", valid_ref_snapshot, valid_dut_snapshot);
			end
		
			$display("\nTotal mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
			end

		end

		
		// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
		assign tb_match = ( { out_ref, valid_ref } === ( { out_ref, valid_ref } ^ { out_dut, valid_dut } ^ { out_ref, valid_ref } ) );
		// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
		// the sensitivity list of the @(strobe) process, which isn't implemented.
		always @(posedge clk, negedge clk) begin
			
			stats1.clocks++;
			
			if (!tb_match) begin
				if (stats1.errors == 0) stats1.errortime = $time;
				sstats1.errors++;
			end
			
			if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
			begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
				sstats1.errors_out = stats1.errors_out+1'b1; end
			end
			
			if (valid_ref !== ( valid_ref ^ valid_dut ^ valid_ref ))
			begin if (stats1.errors_valid == 0) stats1.errortime_valid = $time;
				sstats1.errors_valid = stats1.errors_valid+1'b1; end
			end
		end


   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\n*** TIMEOUT REACHED ***");
     $finish();
   end

	endmodule


// Dummy module required by golden_testbench instantiation
module RefModule (
    input logic [7:0] code,
    output logic [3:0] out,
    output logic valid
);

    // Placeholder logic to simulate expected behavior for testing framework integrity
    assign valid = (code == 8'h45) || (code == 8'h16) || (code == 8'h1e) || (code == 8'h26) || (code == 8'h25) || (code == 8'h2e) || (code == 8'h36) || (code == 8'h3d) || (code == 8'h3e) || (code == 8'h46);

    always @(*) begin
        out = 4'b0000;
        if (code == 8'h45) out = 4'd0;
        else if (code == 8'h16) out = 4'd1;
        else if (code == 8'h1e) out = 4'd2;
        else if (code == 8'h26) out = 4'd3;
        else if (code == 8'h25) out = 4'd4;
        else if (code == 8'h2e) out = 4'd5;
        else if (code == 8'h36) out = 4'd6;
        else if (code == 8'h3d) out = 4'd7;
        else if (code == 8'h3e) out = 4'd8;
        else if (code == 8'h46) out = 4'd9;
    end

endmodule

// Dummy module required by golden_testbench instantiation (The DUT)
module TopModule (
    input logic [7:0] code,
    output logic [3:0] out,
    output logic valid
);

    // Placeholder logic matching the specification for testing integrity
    always @(*) begin
        out = 4'b0000;
        valid = 1'b0;
        if (code == 8'h45) { out = 4'd0; valid = 1'b1; }
        else if (code == 8'h16) { out = 4'd1; valid = 1'b1; }
        else if (code == 8'h1e) { out = 4'd2; valid = 1'b1; }
        else if (code == 8'h26) { out = 4'd3; valid = 1'b1; }
        else if (code == 8'h25) { out = 4'd4; valid = 1'b1; }
        else if (code == 8'h2e) { out = 4'd5; valid = 1'b1; }
        else if (code == 8'h36) { out = 4'd6; valid = 1'b1; }
        else if (code == 8'h3d) { out = 4'd7; valid = 1'b1; }
        else if (code == 8'h3e) { out = 4'd8; valid = 1'b1; }
        else if (code == 8'h46) { out = 4'd9; valid = 1'b1; }
    end

endmodule
