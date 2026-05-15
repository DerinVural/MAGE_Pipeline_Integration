module tb ();
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

    wire tb_match;  // Verification
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .areset(areset),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .wavedrom_hide_after_time(wavedrom_hide_after_time)
    );
    RefModule good1 (
        .clk(clk),
        .areset(areset),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .state(state_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .areset(areset),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .state(state_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask	

    final begin
        if (stats1.errors_state) $display("Hint: Output '"%s"' has %0d mismatches. First mismatch occurred at time %0d.", "state", stats1.errors_state, stats1.errortime_state);
        else $display("Hint: Output '"%s"' has no mismatches.", "state" );
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0)
            $display("SIMULATION PASSED");
        else
            $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors, stats1.errortime);
    end

    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { state_ref } === ( { state_ref } ^ { state_dut } ^ { state_ref } ) );
    // Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
    // the sensitivity list of the @(strobe) process, which isn't implemented.
    always @(posedge clk, negedge clk) begin
		stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (state_ref !== ( state_ref ^ state_dut ^ state_ref ))
        begin if (stats1.errors_state == 0) stats1.errortime_state = $time;
            stats1.errors_state = stats1.errors_state+1'b1; end
		
    end

    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule