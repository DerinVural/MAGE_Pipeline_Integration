`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
    input clk,
    output logic areset,
    output logic bump_left,
    output logic bump_right,
    output logic dig,
    output logic ground,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;

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
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
        // Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
        // a functionality error than the reset being implemented asynchronously.
    
    endtask


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask


    wire [0:13][3:0] d = {
        4'h2,
        4'h2,
        4'h3,
        4'h2,
        4'ha,
        4'h2,
        4'h0,
        4'h0,
        4'h0,
        4'h3,
        4'h2,
        4'h2,
        4'h2,
        4'h2
    };
    
    initial begin
        reset <= 1'b1;
        {bump_left, bump_right, ground, dig} <= 4'h2;
        reset_test(1);

        reset <= 1'b1;
        @(posedge clk);
        reset <= 0;
        
        @(negedge clk);
        wavedrom_start("Digging");
        for (int i=0;i<14;i++) 
            @(posedge clk) {bump_left, bump_right, ground, dig} <= d[i];
        wavedrom_stop();
        
        repeat(400) @(posedge clk, negedge clk) begin
            {dig, bump_right, bump_left} <= $random & $random;
            ground <= |($random & 7);
            reset <= !($random & 31);
        end

        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_walk_left;
        int errortime_walk_left;
        int errors_walk_right;
        int errortime_walk_right;
        int errors_aaah;
        int errortime_aaah;
        int errors_digging;
        int errortime_digging;

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
    logic bump_left;
    logic bump_right;
    logic ground;
    logic dig;
    logic walk_left_ref;
    logic walk_left_dut;
    logic walk_right_ref;
    logic walk_right_dut;
    logic aaah_ref;
    logic aaah_dut;
    logic digging_ref;
    logic digging_dut;

    // Registers to capture state at the first mismatch
    logic clk_snap, areset_snap, bl_snap, br_snap, gnd_snap, dig_snap;
    logic wl_ref_snap, wr_ref_snap, aaah_ref_snap, digg_ref_snap;
    logic wl_dut_snap, wr_dut_snap, aaah_dut_snap, digg_dut_snap;
    
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,bump_left,bump_right,ground,dig,walk_left_ref,walk_left_dut,walk_right_ref,walk_right_dut,aaah_ref,aaah_dut,digging_ref,digging_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .areset,
        .bump_left,
        .bump_right,
        .ground,
        .dig,
        .wavedrom_title,
        .wavedrom_enable,
        .tb_match );
        
    // Assuming RefModule and TopModule exist for compilation context
    RefModule good1 (
        .clk,
        .areset,
        .bump_left,
        .bump_right,
        .ground,
        .dig,
        .walk_left(walk_left_ref),
        .walk_right(walk_right_ref),
        .aaah(aaah_ref),
        .digging(digging_ref) );
        
    TopModule top_module1 (
        .clk,
        .areset,
        .bump_left,
        .bump_right,
        .ground,
        .dig,
        .walk_left(walk_left_dut),
        .walk_right(walk_right_dut),
        .aaah(aaah_dut),
        .digging(digging_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    final begin
        if (stats1.errors == 0)
            $display("SIMULATION PASSED");
        else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            
            $display("\n--- State at First Mismatch Time (%0d ps) ---", stats1.errortime);
            
            // Display Inputs (Ensure proper quoting for multi-line/complex display)
            $display("Inputs: CLK=%b, ARESET=%b, BUMP_L=%b, BUMP_R=%b, GROUND=%b, DIG=%b", 
                clk_snap, areset_snap, bl_snap, br_snap, gnd_snap, dig_snap);
            
            // Display DUT Outputs
            $display("Outputs (DUT): WL=%b, WR=%b, AAAH=%b, DIGGING=%b", 
                wl_dut_snap, wr_dut_snap, aaah_dut_snap, digg_dut_snap);
            
            // Display Reference Outputs
            $display("Outputs (Reference): WL=%b, WR=%b, AAAH=%b, DIGGING=%b", 
                wl_ref_snap, wr_ref_snap, aaah_ref_snap, digg_ref_snap);
            
            $display("---------------------------------------------");
        end
        
        $display("Simulation finished at %0d ps", $time);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } === ( { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } ^ { walk_left_dut, walk_right_dut, aaah_dut, digging_dut } ^ { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } ) );
    // Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
    // the sensitivity list of the @(strobe) process, which isn't implemented.
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;

        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // Capture state ONLY when the *first* error is detected (stats1.errors == 1)
        if (stats1.errors == 1) begin
            clk_snap <= clk;
            areset_snap <= areset;
            bl_snap <= bump_left;
            br_snap <= bump_right;
            gnd_snap <= ground;
            dig_snap <= dig;
            wl_ref_snap <= walk_left_ref;
            wr_ref_snap <= walk_right_ref;
            aaah_ref_snap <= aaah_ref;
            digg_ref_snap <= digging_ref;
            wl_dut_snap <= walk_left_dut;
            wr_dut_snap <= walk_right_dut;
            aaah_dut_snap <= aaah_dut;
            digg_dut_snap <= digging_dut;
        end
        
        // Individual error counting (maintaining original logic)
        if (walk_left_ref !== ( walk_left_ref ^ walk_left_dut ^ walk_left_ref ))
        begin if (stats1.errors_walk_left == 0) stats1.errortime_walk_left = $time;
            stats1.errors_walk_left = stats1.errors_walk_left+1'b1; end
        if (walk_right_ref !== ( walk_right_ref ^ walk_right_dut ^ walk_right_ref ))
        begin if (stats1.errors_walk_right == 0) stats1.errortime_walk_right = $time;
            stats1.errors_walk_right = stats1.errors_walk_right+1'b1; end
        if (aaah_ref !== ( aaah_ref ^ aaah_dut ^ aaah_ref ))
        begin if (stats1.errors_aaah == 0) stats1.errortime_aaah = $time;
            stats1.errors_aaah = stats1.errors_aaah+1'b1; end
        if (digging_ref !== ( digging_ref ^ digging_dut ^ digging_ref ))
        begin if (stats1.errors_digging == 0) stats1.errortime_digging = $time;
            stats1.errors_digging = stats1.errors_digging+1'b1; end
        end

    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule
