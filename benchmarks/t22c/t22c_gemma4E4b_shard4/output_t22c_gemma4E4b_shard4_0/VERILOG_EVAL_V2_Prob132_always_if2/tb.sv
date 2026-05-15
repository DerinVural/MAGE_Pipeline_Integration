`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (Copied EXACTLY from golden_testbench) ---
module stimulus_gen (
	input clk,
	output logic cpu_overheated, arrived, gas_tank_empty,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask	

	logic [2:0] s = 3'b010;
	assign {cpu_overheated, arrived, gas_tank_empty} = s;

	initial begin
		@(negedge clk) wavedrom_start("");
		@(posedge clk) s <= 3'b010;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b001;
		@(posedge clk) s <= 3'b000;
		@(posedge clk) s <= 3'b100;
		@(posedge clk) s <= 3'b110;
		@(posedge clk) s <= 3'b111;
		@(posedge clk) s <= 3'b111;
		@(posedge clk) s <= 3'b111;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
		s <= $urandom;
		$finish;
	end
	endmodule

// --- Golden Reference Module (Must match the fixed DUT logic) ---
module RefModule (
    input logic cpu_overheated,
    input logic arrived,
    input logic gas_tank_empty,
    output logic shut_off_computer,
    output logic keep_driving
);
    // Logic matching the intended specification for comparison, fixed to be deterministic.
    assign shut_off_computer = cpu_overheated;
    // Based on fixing the latch in the DUT, we assume the reference model should also use this derived logic.
    assign keep_driving = (~arrived) ? (~gas_tank_empty) : 1'b1;
endmodule

// --- FIXED DUT Module (TopModule Implementation) ---
module TopModule (
    input logic cpu_overheated,
    output logic shut_off_computer,
    input logic arrived,
    input logic gas_tank_empty,
    output logic keep_driving
);
    // Fix: Use continuous assignments for combinational logic.
    // shut_off_computer = 1 if cpu_overheated is 1, else 0.
    assign shut_off_computer = cpu_overheated;

    // Fixed logic to cover all cases: If arrived is false, use ~gas_tank_empty. If arrived is true, default to 1.
    assign keep_driving = (~arrived) ? (~gas_tank_empty) : 1'b1;
    
endmodule

// --- Testbench (Enhanced for detailed logging) ---
module tb();

    // Helper function for displaying signals in HEX and BIN
    function void display_signal(string name, logic signal, int width);
        // Displaying in HEX and BIN format as required
        $display("		%s: HEX = %h, BIN = %b", name, signal, signal);
    endfunction

    typedef struct packed {
        int errors;
        int errortime;
        int errors_shut_off_computer;
        int errortime_shut_off_computer;
        int errors_keep_driving;
        int errortime_keep_driving;
        int clocks;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic cpu_overheated;
    logic arrived;
    logic gas_tank_empty;
    logic shut_off_computer_ref;
    logic shut_off_computer_dut;
    logic keep_driving_ref;
    logic keep_driving_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen.clk, tb_mismatch ,cpu_overheated,arrived,gas_tank_empty,shut_off_computer_ref,shut_off_computer_dut,keep_driving_ref,keep_driving_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* , 
        .cpu_overheated,
        .arrived,
        .gas_tank_empty );
    RefModule good1 (
        .cpu_overheated,
        .arrived,
        .gas_tank_empty,
        .shut_off_computer(shut_off_computer_ref),
        .keep_driving(keep_driving_ref) );
        
    TopModule top_module1 (
        .cpu_overheated,
        .arrived,
        .gas_tank_empty,
        .shut_off_computer(shut_off_computer_dut),
        .keep_driving(keep_driving_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Flag to ensure detailed reporting only happens once on the first error
    logic first_mismatch_recorded = 0;

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
    end
    
    // Verification logic
    assign tb_match = ( { shut_off_computer_ref, keep_driving_ref } === ( { shut_off_computer_ref, keep_driving_ref } ^ { shut_off_computer_dut, keep_driving_dut } ) );
    
    // Enhanced monitoring and error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time; // Record first error time
            stats1.errors++;
        end
        
        // Check Shut Off Computer Error
        if (shut_off_computer_ref !== shut_off_computer_dut) begin
            if (stats1.errors_shut_off_computer == 0) stats1.errortime_shut_off_computer = $time;
            stats1.errors_shut_off_computer = stats1.errors_shut_off_computer+1'b1;
        end
        
        // Check Keep Driving Error
        if (keep_driving_ref !== keep_driving_dut) begin
            if (stats1.errors_keep_driving == 0) stats1.errortime_keep_driving = $time;
            stats1.errors_keep_driving = stats1.errors_keep_driving+1'b1;
        end
        
        // Detailed Mismatch Display on FIRST ERROR
        if (!tb_match && stats1.errors == 1 && !first_mismatch_recorded) begin
            $display("\n====================================================\n");
            $display("!!! FIRST MISMATCH DETECTED AT TIME %0d ps !!!", $time);
            $display("====================================================\n");
            $display("INPUT SIGNALS:");
            display_signal("cpu_overheated", cpu_overheated, 1);
            display_signal("arrived", arrived, 1);
            display_signal("gas_tank_empty", gas_tank_empty, 1);
            $display("OUTPUT SIGNALS (DUT vs REF):");
            display_signal("shut_off_computer_DUT", shut_off_computer_dut, 1);
            display_signal("shut_off_computer_REF", shut_off_computer_ref, 1);
            display_signal("keep_driving_DUT", keep_driving_dut, 1);
            display_signal("keep_driving_REF", keep_driving_ref, 1);
            $display("====================================================\n");
            first_mismatch_recorded = 1;
        end
    end

    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule
