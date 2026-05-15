`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg ring,
	output reg vibrate_mode,
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
	int count; count = 0;
	{vibrate_mode,ring} <= 1'b0;
	wavedrom_start();
	repeat(10) @(posedge clk)
		{vibrate_mode,ring} <= count++;
	wavedrom_stop();
	
	#1 $finish;
end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_ringer;
		int errortime_ringer;
		int errors_motor;
		int errortime_motor;

		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;

	initial forever
		#5 clk = ~clk;


logic ring;
logic vibrate_mode;
logic ringer_ref;
logic ringer_dut;
logic motor_ref;
logic motor_dut;


initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,ring,vibrate_mode,ringer_ref,ringer_dut,motor_ref,motor_dut );
end


wire tb_match;	// Verification
wire tb_mismatch = ~tb_match;
	

stimulus_gen stim1 (
		.clk,
		.* , 
		.ring,
		vibrate_mode );
RefModule good1 (
		.ring,
		vibrate_mode,
		ringer(ringer_ref),
		.motor(motor_ref) );

TopModule top_module1 (
		.ring,
		vibrate_mode,
		ringer(ringer_dut),
		.motor(motor_dut) );




	// Function to display signals in required format
	task display_signals;
		input logic r_in, vm_in, r_ref_out, m_ref_out, r_dut_out, m_dut_out;
		
		$display("
========================================================================");
		$display("*** MISMATCH DETECTED *** (Time: %0t ps)", $time);
		$display("------------------------------------------------------------------------");
		
		// Display Inputs
		$display("Inputs: ring=%b (HEX: %h), vibrate_mode=%b (HEX: %h)", r_in, r_in, vm_in, vm_in);
		// Display Expected Outputs
		$display("Expected Outputs: ringer=%b (HEX: %h), motor=%b (HEX: %h)", r_ref_out, r_ref_out, m_ref_out, m_ref_out);
		// Display Actual Outputs
		$display("Actual Outputs: ringer=%b (HEX: %h), motor=%b (HEX: %h)", r_dut_out, r_dut_out, m_dut_out, m_dut_out);
		$display("========================================================================");
	endtask



	// Initialize stats
	initial begin
		stats1 = '{default: 0};
	end


// Use explicit sensitivity list here.
always @(posedge clk) begin
	
		stats1.clocks++;
	
		// --- Overall Mismatch Check ---
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			// Display detailed info for the first overall mismatch
			if (stats1.errors == 1) begin
				display_signals(ring, vibrate_mode, ringer_ref, motor_ref, ringer_dut, motor_dut);
			end
		end
	
		// --- Ringer Mismatch Check ---
		if (ringer_ref !== ringer_dut) begin // Simplified check for 1-bit signals
			if (stats1.errors_ringer == 0) stats1.errortime_ringer = $time;
			sstats1.errors_ringer++;
			// Display detailed info for the first ringer mismatch
			if (stats1.errors_ringer == 1) begin
				display_signals(ring, vibrate_mode, ringer_ref, motor_ref, ringer_dut, motor_dut);
			end
		end
	
		// --- Motor Mismatch Check ---
		if (motor_ref !== motor_dut) begin // Simplified check for 1-bit signals
			if (stats1.errors_motor == 0) stats1.errortime_motor = $time;
			sstats1.errors_motor++;
			// Display detailed info for the first motor mismatch
			if (stats1.errors_motor == 1) begin
				display_signals(ring, vibrate_mode, ringer_ref, motor_ref, ringer_dut, motor_dut);
			end
		end
	endmodule


// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT: Simulation terminated prematurely.");
	$finish();
end

endmodule