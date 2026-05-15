`timescale 1ps/1ps
module tb();
	reg clk = 0;
	initial forever #5 clk = ~clk;
	logic [7:0] in;
	logic [7:0] out_ref, out_dut;
	logic [511:0] wavedrom_title;
	logic wavedrom_enable;
	logic [511:0] wavedrom_title_reg = 0;
	aSSIGN wavedrom_title = wavedrom_title_reg;
	aSSIGN wavedrom_enable = 1;
	// Instantiate DUT and reference module
	TopModule top_module1( .clk(), .in(in), .out(out_dut) ); // clk port not in TopModule as per spec
	RefModule good1( .clk(), .in(in), .out(out_ref) ); // Assuming RefModule has clk port
	sTATS;
		integer errors = 0, errortime = -1, clocks = 0;
		integer errors_out = 0, errortime_out = -1;
	// Stimulus and monitoring
	initial begin
		in = 8'h00;
		@(negedge clk);
		in = 8'hFF;
	end
	// Check outputs on clock edges
	eVERY @(posedge clk or negedge clk) begin
		clocks++;
		if (out_ref !== out_dut) begin
			if (errors == 0) errortime = $time;
			errors++;
		end
		if (out_ref !== out_dut) begin
			if (errors_out == 0) errortime_out = $time;
			errors_out++;
		end
	end
	// Display results
	final begin
		if (errors) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
		end else begin
			$display("SIMULATION PASSED");
		end
	end
	// Timeout after 100k cycles
	initial begin #100000; $display("TIMEOUT"); $finish; end
endmodule