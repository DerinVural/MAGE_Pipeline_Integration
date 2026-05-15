`timescale 1ps/1ps
module tb();
    reg a, b, c, d;
    wire q_ref, q_dut;
    reg [511:0] wavedrom_title;
    reg wavedrom_enable;
    // Instantiate modules
    RefModule ref_inst (.a(a), .b(b), .c(c), .d(d), .q(q_ref));
    TopModule dut_inst (.a(a), .b(b), .c(c), .d(d), .q(q_dut));
    // Stimulus generation
    initial begin
        a = 0; b = 0; c = 0; d = 0;
        #0;
        #5; // Time 5ns: values same
        #10; // Time 10ns: same
        #15; // Time 15ns: same
        #20; d = 1; // Time 20ns
        #5; // 25ns: a=0, b=1, c=1, d=0 (q=1)
        #5; // 30ns: b=1, c=1, d=1 (q=1)
        #5; // 35ns: b=1
        #5; // 40ns: b=1, d=1 (q=1)
        #5; // 45ns: c=1
        #5; // 50ns: all c=1, d=1 (q=1)
        #5; a =1; d=0; // Time 55ns
        #5; d=1; // 60ns: q=0
        #5; d=0; // 65ns: q=1
        #5; d=1; // 70ns: q=1
        #5; // 75ns: d=0 (q=1)
        #5; // 80ns: d=1 (q=1)
        #5; // 85ns: c=1 (q=1)
        #5; // 90ns: d=1 (q=1)
        #500; // Timeout after 100ns*5=500ns
        $finish;
    end
    // Error detection logic
    integer errors=0, errortime, clocks=0;
    always @(posedge d or negedge d) begin
        clocks++;
        if (q_ref !== q_dut) begin
            errors++;
            if (errors==1) errortime=$time;
        end
    end
    // Simulation end display
    initial begin
        wait(clocks>0);
        if (errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule
