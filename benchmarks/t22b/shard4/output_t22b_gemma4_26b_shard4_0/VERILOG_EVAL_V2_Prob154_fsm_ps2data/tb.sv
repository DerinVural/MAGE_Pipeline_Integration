`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [7:0] in,
    output logic reset
);

    initial begin
        repeat(200) @(negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
        end
        reset <= 1'b0;
        in <= '0;
        repeat(10) @(posedge clk);
        
        repeat(200) begin
            in <= $random;
            in[3] <= 1'b1;
            @(posedge clk);
            in <= $random;
            @(posedge clk);
            in <= $random;
            @(posedge clk);
        end

        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_bytes;
        int errortime_out_bytes;
        int errors_done;
        int errortime_done;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [7:0] in;
    logic reset;
    logic [23:0] out_bytes_ref;
    logic [23:0] out_bytes_dut;
    logic done_ref;
    logic done_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, in, reset, out_bytes_ref, out_bytes_dut, done_ref, done_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .in,
        .reset 
    );

    RefModule good1 (
        .clk,
        .in,
        .reset,
        .out_bytes(out_bytes_ref),
        .done(done_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .in,
        .reset,
        .out_bytes(out_bytes_dut),
        .done(done_dut) 
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { out_bytes_ref, done_ref } === ( { out_bytes_ref, done_ref } ^ { out_bytes_dut, done_dut } ^ { out_bytes_ref, done_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Display first mismatch details
                $display("\n[FIRST MISMATCH DETECTED AT TIME %0t]", $time);
                $display("Inputs: in=%h (bin:%b), reset=%b", in, in, reset);
                $display("DUT Outputs: out_bytes=%h (bin:%b), done=%b", out_bytes_dut, out_bytes_dut, done_dut);
                $display("Expected:    out_bytes=%h (bin:%b), done=%b", out_bytes_ref, out_bytes_ref, done_ref);
            end
            stats1.errors++;
        end

        if (out_bytes_ref !== ( out_bytes_ref ^ out_bytes_dut ^ out_bytes_ref )) begin 
            if (stats1.errors_out_bytes == 0) stats1.errortime_out_bytes = $time;
            stats1.errors_out_bytes = stats1.errors_out_bytes + 1'b1; 
        end

        if (done_ref !== ( done_ref ^ done_dut ^ done_ref )) begin 
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done = stats1.errors_done + 1'b1; 
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("\nSIMULATION PASSED");
        end else begin
            $display("\nSIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_out_bytes) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_bytes", stats1.errors_out_bytes, stats1.errortime_out_bytes);
        else $display("Hint: Output '%s' has no mismatches.", "out_bytes");
        
        if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else $display("Hint: Output '%s' has no mismatches.", "done");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule