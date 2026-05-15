`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic in,
    output logic reset
);

    initial begin
        reset <= 1;
        in <= 1;
        @(posedge clk);
        reset <= 0;
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(10) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(10) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        
        repeat(800) @(posedge clk, negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
        end

        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_byte;
        int errortime_out_byte;
        int errors_done;
        int errortime_done;
        int clocks;
    } stats;
    
    stats stats1;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic in;
    logic reset;
    logic [7:0] out_byte_ref;
    logic [7:0] out_byte_dut;
    logic done_ref;
    logic done_dut;

    // Queues for error reporting
    logic in_q [$];
    logic reset_q [$];
    logic [7:0] out_byte_dut_q [$];
    logic [7:0] out_byte_ref_q [$];
    logic done_dut_q [$];
    logic done_ref_q [$];
    localparam MAX_QUEUE_SIZE = 10;

    bit first_mismatch_logged = 0;
    bit mismatch_occurred = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_byte_ref,out_byte_dut,done_ref,done_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .in,
        .reset 
    );

    RefModule good1 (
        .clk,
        .in,
        .reset,
        .out_byte(out_byte_ref),
        .done(done_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .in,
        .reset,
        .out_byte(out_byte_dut),
        .done(done_dut) 
    );

    assign tb_match = ( { out_byte_ref, done_ref } === ( { out_byte_ref, done_ref } ^ { out_byte_dut, done_dut } ^ { out_byte_ref, done_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Maintain queues
        if (in_q.size() >= MAX_QUEUE_SIZE) begin
            in_q.delete(0);
            reset_q.delete(0);
            out_byte_dut_q.delete(0);
            out_byte_ref_q.delete(0);
            done_dut_q.delete(0);
            done_ref_q.delete(0);
        end

        in_q.push_back(in);
        reset_q.push_back(reset);
        out_byte_dut_q.push_back(out_byte_dut);
        out_byte_ref_q.push_back(out_byte_ref);
        done_dut_q.push_back(done_dut);
        done_ref_q.push_back(done_ref);

        stats1.clocks++;

        if (!tb_match) begin
            mismatch_occurred = 1;
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Display first mismatch details
            if (!first_mismatch_logged) begin
                $display("\nMismatch detected at time %t", $time);
                $display("Last %d cycles of simulation:", in_q.size());
                for (int i = 0; i < in_q.size(); i++) begin
                    $display("Cycle %d, reset %b, in %b, got_out_byte %h(%b), exp_out_byte %h(%b), got_done %b, exp_done %b",
                        i, reset_q[i], in_q[i], out_byte_dut_q[i], out_byte_dut_q[i], out_byte_ref_q[i], out_byte_ref_q[i], done_dut_q[i], done_ref_q[i]);
                end
                first_mismatch_logged = 1;
            end
        end

        if (out_byte_ref !== ( out_byte_ref ^ out_byte_dut ^ out_byte_ref )) begin
            if (stats1.errors_out_byte == 0) stats1.errortime_out_byte = $time;
            stats1.errors_out_byte = stats1.errors_out_byte+1'b1;
        end

        if (done_ref !== ( done_ref ^ done_dut ^ done_ref )) begin
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done = stats1.errors_done+1'b1;
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (mismatch_occurred) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end

        if (stats1.errors_out_byte) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_byte", stats1.errors_out_byte, stats1.errortime_out_byte);
        else $display("Hint: Output '%s' has no mismatches.", "out_byte");
        if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else $display("Hint: Output '%s' has no mismatches.", "done");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule