`timescale 1ps/1ps
module tb();
    // Wavedrom signals not used in functionality
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [3:0] in;
    logic out_and_ref, out_and_dut;
    logic out_or_ref, out_or_dut;
    logic out_xor_ref, out_xor_dut;

    stimulus_gen stim1 ( 
        .clk(clk),
        .in(in)
    );

    TopModule top_module1 ( 
        .in(in),
        .out_and(out_and_dut),
        .out_or(out_or_dut),
        .out_xor(out_xor_dut)
    );

    RefModule good1 ( 
        .in(in),
        .out_and(out_and_ref),
        .out_or(out_or_ref),
        .out_xor(out_xor_ref)
    );

    // Statistics variables
    int errors = 0, errortime = 0;
    int errors_out_and = 0, errortime_out_and = 0;
    int errors_out_or = 0, errortime_out_or = 0;
    int errors_out_xor = 0, errortime_out_xor = 0;
    int clocks = 0;

    // Timeout after 100,000 ns
    initial begin
        #100000 $display("TIMEOUT"); $finish;
    end

    // Error checking logic
    always @(posedge clk, negedge clk) begin
        clocks++;
        // AND gate check
        if (out_and_ref !== (out_and_ref ^ out_and_dut ^ out_and_ref)) begin
            if (errors == 0) errortime = $time;
            errors += 1;
            if (errors_out_and == 0) errortime_out_and = $time;
            errors_out_and += 1;
        end
        // OR gate check
        if (out_or_ref !== (out_or_ref ^ out_or_dut ^ out_or_ref)) begin
            if (errors_out_or == 0) errortime_out_or = $time;
            errors_out_or += 1;
        end
        // XOR gate check
        if (out_xor_ref !== (out_xor_ref ^ out_xor_dut ^ out_xor_ref)) begin
            if (errors_out_xor == 0) errortime_out_xor = $time;
            errors_out_xor += 1;
        end
    end

    // Final report
    final begin
        if (errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
            $display("First Mismatch:\nTime=%0d in=%b\nout_and_ref=%b vs out_and_dut=%b",
                errortime, in, out_and_ref, out_and_dut);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule