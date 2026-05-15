`timescale 1ps/1ps

module stimulus_gen(clk, in);
    input clk;
    output logic [7:0] in;
    initial begin
        repeat(100) @(posedge clk, negedge clk) in <= $random;
        $finish;
    end
endmodule

module tb();
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [7:0] in;
    logic parity_ref, parity_dut;
    wire tb_match = ({parity_ref} === ({parity_ref} ^ {parity_dut} ^ {parity_ref}));

    reg [15:0] errors = 0, errortime = 0, errors_parity = 0, errortime_parity = 0, clocks = 0;

    stimulus_gen stim(.clk(clk), .in(in));
    RefModule ref_mod(.in(in), .parity(parity_ref));
    TopModule top_inst(.in(in), .parity(parity_dut));

    always @(posedge clk) begin
        clocks += 1;
        if (!tb_match) begin
            if (errors == 0) errortime = $time;
            errors += 1;
        end
        if (parity_ref !== (parity_ref ^ parity_dut ^ parity_ref)) begin
            if (errors_parity == 0) errortime_parity = $time;
            errors_parity += 1;
        end
    end

    initial begin
        #1000000 $display("TIMEOUT"); $finish;
    end

    final begin
        if (errors_parity) $display("Hint: Output 'parity' has %0d mismatches. First at time %0d", errors_parity, errortime_parity);
        else $display("Hint: Output 'parity' no mismatches");
        $display("Mismatches: %0d in %0d samples", errors, clocks);
        $display("Simulation finished at %0t", $time);
        if (errors) $display("SIMULATION FAILED - %0d MISMATCHES, FIRST AT %0t", errors, errortime);
        else $display("SIMULATION PASSED");
    end
endmodule