`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Module stimulus_gen (Kept as is, ensuring it compiles)
module stimulus_gen (
	input clk,
	output logic in,
	output logic reset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
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
		s
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask
	
	
	initial begin
		reset <= 1;
		in <= 0;
		@(posedge clk);
		@(posedge clk) reset <= 0; in <= 0;
		@(posedge clk) in <= 1;
		wavedrom_start();
		reset_test(0);
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 1;
		@(posedge clk) in <= 1;
		@(negedge clk);
		wavedrom_stop();
		repeat(200) @(posedge clk, negedge clk) begin
		in <= $random;
		reset <= !($random & 7);
		end

		h#1 $finish;
	end
	endmodule

// TopModule (DUT) - Implementation from previous step
module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State Definition (2 states: A, B)
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register (1 bit needed)
    logic [0:0] state;
    logic [0:0] state_next;

    // Initialize state register to a known value before reset takes effect
    initial begin
        state = STATE_A; // Initialize to A
    end

    // State Register Logic (Sequential)
    always @(posedge clk)
    begin
        if (reset)
            state <= STATE_B; // Reset state is B (active high synchronous reset)
        else
            state <= state_next;
    end

    // Next State Combinational Logic
    always @(*)
    begin
        state_next = state;

        case (state)
            STATE_A:
                if (in == 0) 
                    state_next = STATE_B; // A --in=0--> B
                else 
                    state_next = STATE_A; // A --in=1--> A

            STATE_B:
                if (in == 0) 
                    state_next = STATE_A; // B --in=0--> A
                else 
                    state_next = STATE_B; // B --in=1--> B

            default: state_next = STATE_A;
        endcase
    end

    // Output Logic (Moore Machine: output depends only on current state)
    always @(*)
    begin
        out = 1'b0;
        case (state)
            STATE_A: out = 1'b0; // A (out=0)
            STATE_B: out = 1'b1; // B (out=1)
            default: out = 1'b0;
        endcase
    end

endmodule


// Testbench
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic in;
    logic reset;
    logic out_ref;
    logic out_dut;

    // Variables to capture state at the first mismatch
    logic first_error_occurred_overall = 0;
    int first_error_time_overall = 0;
    logic captured_in = 0;
    logic captured_reset = 0;
    logic captured_out_ref = 0;
    logic captured_out_dut = 0;

    initial begin 
        $dumpfile("wave.vcd");
        // Note: stim1 must be defined before this line for $dumpvars to work on it.
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_ref,out_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus_gen, matching the structure implied by the golden TB
    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match)
    );

    // Instantiate Reference Module (Black Box/Golden) - Assume RefModule exists
    RefModule good1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .out(out_ref)
    );
        
    // Instantiate DUT
    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .out(out_dut)
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    final begin
        // 1. Check for overall pass/fail condition
        if (stats1.errors == 0 && stats1.errors_out == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            // Failure case: Display required format
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors + stats1.errors_out, first_error_time_overall);
            
            // 2. Display first mismatch details
            $display("
--- FIRST MISMATCH DETAILS @ %0d ps ---", first_error_time_overall);
            // Displaying signals in required format (binary is sufficient for 1-bit signals)
            $display("Input Signals (clk, reset, in): clk=%b, reset=%b, in=%b", clk, reset, in);
            $display("Output Signals (out_ref, out_dut): out_ref=%b, out_dut=%b", out_ref, out_dut);
            $display("Expected Output Signal: out_ref=%b", out_ref);
            $display("-------------------------------------");
        end
        
        // Original functional displays
        $display("Hint: Output 'out' has %0d mismatches.", stats1.errors_out);
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // State tracking logic
    always @(posedge clk, negedge clk) begin
        
        stats1.clocks++;
        
        // Check 1: Overall mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                first_error_time_overall = $time;
                captured_in = in;
                captured_reset = reset;
                captured_out_ref = out_ref;
                captured_out_dut = out_dut;
            end
            stats1.errors++;
        end
        
        // Check 2: Output mismatch
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) begin
                stats1.errortime_out = $time;
                // Capture time/state if this is the first *output* mismatch
                if (first_error_time_overall == 0 || $time < first_error_time_overall) begin
                    first_error_time_overall = $time;
                end
                captured_in = in;
                captured_reset = reset;
                captured_out_ref = out_ref;
                captured_out_dut = out_dut;
            end
            $display("Error detected for out at time %0d", $time);
            stats1.errors_out = stats1.errors_out+1'b1; 
        end

    end

    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule

// Dummy definitions for compilation, matching golden testbench structure
module RefModule (input logic clk, input logic in, input logic reset, output logic out); endmodule