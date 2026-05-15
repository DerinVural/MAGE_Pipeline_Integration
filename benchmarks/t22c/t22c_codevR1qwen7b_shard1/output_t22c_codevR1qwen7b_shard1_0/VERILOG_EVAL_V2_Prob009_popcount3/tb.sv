// `timescale 1ps/1ps

module tb();
    logic [2:0] in;
    logic [1:0] out_ref, out_dut;
    int errors, errortime, errors_out;
    int clocks;
    logic clk = 0;
    reg [511:0] wavedrom_title;
    reg wavedrom_enable;
    initial begin
        forever #5 clk = ~clk;
    end

    // Reference module (built-in calculation)
    always_comb begin
        out_ref = in[0] + in[1] + in[2];
    end

    // DUT instance
    TopModule dut_inst(.in(in), .out(out_dut));

    // Stimulus generation
    initial begin
        in = 7;
        #(10); // Wait for first negedge
        repeat(9) @(posedge clk) in <= in + 1;
        #(200);
        repeat(200) in <= $urandom_range(7,0);
        #(1000000);
        $finish;
    end

    // Error checking
    always @(posedge clk, negedge clk) begin
        clocks++;
        if (out_ref !== out_dut) begin
            if (errors == 0) errortime = $time;
            errors++;
        end
    end

    // Timeout handling
    initial begin
        #1000000 $display("TIMEOUT"); $finish;
    end

    // Simulation end
    final begin
        if (errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule