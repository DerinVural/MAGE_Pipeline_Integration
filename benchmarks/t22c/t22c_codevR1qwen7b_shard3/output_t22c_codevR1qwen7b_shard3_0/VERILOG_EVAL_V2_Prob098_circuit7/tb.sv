module tb();
    reg clk = 0;
    logic a;
    logic q_ref, q_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;

    // Clock generation
    initial forever #5 clk = ~clk;

    // Stimulus
    initial begin
        a <= 0;
        @(posedge clk);
        repeat(100) a <= $urandom;
        #1000000 $finish;
    end

    // Instantiate DUT and reference
    TopModule top_module1(clk, a, q_dut);
    RefModule good1(clk, a, q_ref);

    // Match check
    assign tb_match = ( {q_ref} === ( {q_ref} ^ {q_dut} ^ {q_ref} ) );
    // Error counting
    reg [3:0] errors = 0, errortime_q = 0, clocks = 0;
    always @(posedge clk) begin clocks++; end
    always @(posedge clk, negedge clk) begin
        if (!tb_match) begin
            if (!errors) errortime_q = $time;
            errors++;
        end
    end
    // Queue setup for first mismatch display
    reg [1:0] input_queue [0:8];
    reg [0:8] got_q, exp_q;
    always @(posedge clk, negedge clk) begin
        if (clocks >= 9) begin
            input_queue[clocks %9] = a;
            got_q[clocks %9] = q_dut;
            exp_q[clocks %9] = q_ref;
        end
    end
    // Simulation end display
    final begin
        if (errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", errors, errortime_q);
            // Print queue up to first mismatch
            for (int i=0; i<9; i++) begin
                if (i < clocks && (got_q[i] !== exp_q[i]))
                    $display("Cycle %0d, a=%h, q_dut=%h, q_ref=%h", i*5, input_queue[i], got_q[i], exp_q[i]);
            end
        end else $display("SIMULATION PASSED");
    end
endmodule