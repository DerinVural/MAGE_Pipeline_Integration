`timescale 1ps/1ps
module tb();
    logic clk;
    logic a, b;
    logic q, q_ref, q_dut;
    logic tb_match, tb_mismatch;

    // Clock generation (not used but in golden testbench)
    always #5 clk = ~clk;

    // Stimulus generation
    initial begin
        a = 0; b = 0; // 0ns
        #5; //5ns
        a = 0; b = 0; //5ns
        #5; //10ns
        a = 0; b = 0; //10ns
        #5; //15ns
        a = 0; b = 1; //15ns
        #5; //20ns
        a = 0; b = 1; //20ns
        #5; //25ns
        a = 1; b = 0; //25ns
        #5; //30ns
        a = 1; b = 0; //30ns
        #5; //35ns
        a = 1; b = 1; //35ns
        #5; //40ns
        a = 1; b = 1; //40ns
        #5; //45ns
        a = 0; b = 0; //45ns
        #5; //50ns
        a = 0; b = 0; //50ns
        #5; //55ns
        a = 0; b = 1; //55ns
        #5; //60ns
        a = 0; b = 1; //60ns
        #5; //65ns
        a = 1; b = 0; //65ns
        #5; //70ns
        a = 1; b = 0; //70ns
        #5; //75ns
        a = 1; b = 1; //75ns
        #5; //80ns
        a = 1; b = 1; //80ns
        #5; //85ns
        a = 1; b = 1; //85ns
        #5; //90ns
        a = 1; b = 1; //90ns
        #5; //95ns
        // ... continue timing to cover all points
        #5; //100ns
        // Add assignments up to required times
        $finish;
    end

    // Instantiate modules
    TopModule top_module1 (.a(a), .b(b), .q(q));
    RefModule ref1 (.a(a), .b(b), .q(q_ref));

    // Verification logic
    always @(posedge clk) begin
        if (tb_mismatch)
            tb_match = 0;
        else
            tb_match = (q_ref === q);
    end

    reg [255:0] errors = 0, errortime, errors_q = 0, errortime_q = 0, clocks = 0;
    always @(negedge clk) begin
        if (!tb_match) begin
            errors++;
            if (errors == 1)
                $display("First mismatch at time %0d: a=%b, b=%b, q_ref=%b, q_dut=%b", $time, a, b, q_ref, q);
        end
        if (q !== q_ref) begin
            errors_q++;
            if (errors_q == 1)
                $display("First q mismatch at time %0d: a=%b, b=%b, q_ref=%b, q_dut=%b", $time, a, b, q_ref, q);
        end
        clocks++;
    end

    // Simulation timeout after 100ns
    initial begin
        #100 $display("TIMEOUT
SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
        $finish;
    end

    // Simulation completion
    initial begin
        wait(clocks >= 18); // Adjust based on timing
        if (!errors && !errors_q)
            $display("SIMULATION PASSED");
        $finish;
    end
endmodule