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
    reg clk = 0;
    reg areset;
    reg bump_left;
    reg bump_right;
    reg ground;
    reg dig;
    reg[511:0] wavedrom_title;
    reg wavedrom_enable;
    wire tb_match;
    wire tb_mismatch = ~tb_match;

    TopModule top_module1 (
        .clk(clk),
        .areset(areset),
        .bump_left(bump_left),
        .bump_right(bump_right),
        .ground(ground),
        .dig(dig),
        .walk_left(walk_left_dut),
        .walk_right(walk_right_dut),
        .aaah(aaah_dut),
        .digging(digging_dut)
    );

    RefModule ref_module (
        .clk(clk),
        .areset(areset),
        .bump_left(bump_left),
        .bump_right(bump_right),
        .ground(ground),
        .dig(dig),
        .walk_left(walk_left_ref),
        .walk_right(walk_right_ref),
        .aaah(aaah_ref),
        .digging(digging_ref)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus generation
    initial begin
        areset = 1;
        bump_left = 0;
        bump_right = 0;
        ground = 1;
        dig = 0;
        wavedrom_title = 0;
        wavedrom_enable = 0;
        // Stimulus sequence from golden testbench
        // ... Add the stimulus sequence here
        #100; // Example timing
    end

    // Error checking and display logic
    // ... Original error checking code here

    // Simulation timeout
    initial #1000000 $display("TIMEOUT");

    initial begin
        #1;
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
        $finish;
    end
endmodule