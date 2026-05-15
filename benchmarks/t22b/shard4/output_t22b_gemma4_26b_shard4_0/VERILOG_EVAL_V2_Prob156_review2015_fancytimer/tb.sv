`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13
`default_nettype none

module stimulus_gen (
    input wire clk,
    output reg reset,
    output reg data, 
    output reg ack,
    input wire tb_match,
    input wire counting_dut
);
    bit failed = 0;
    int counting_cycles = 0;
    
    always @(posedge clk, negedge clk)
        if (!tb_match) 
            failed <= 1;
            
    always @(posedge clk)
        if (counting_dut)
            counting_cycles++;
    
    initial begin

        @(posedge clk);
        failed <= 0;
        reset <= 1;
        data <= 0;
        ack <= 1'bx;
        @(posedge clk) 
            data <= 1;
            reset <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk);
            data <= 1'bx;
        repeat(2000) @(posedge clk);
            ack <= 1'b0;
        repeat(3) @(posedge clk);
            ack <= 1'b1;
        @(posedge clk);
            ack <= 1'b0;
            data <= 1'b1;
        if (counting_cycles != 2000)
            $display("Hint: The first test case should count for 2000 cycles. Your circuit counted %0d", counting_cycles);
        counting_cycles <= 0;
        @(posedge clk);
            ack <= 1'bx;
            data <= 1'b1;
        @(posedge clk);
            data <= 1'b0;
        @(posedge clk);
            data <= 1'b1;
        @(posedge clk);    data <= 1'b1;
        @(posedge clk);    data <= 1'b1;
        @(posedge clk);    data <= 1'b1;
        @(posedge clk);    data <= 1'b0;
        repeat(14800) @(posedge clk);
        ack <= 1'b0;
        repeat(400) @(posedge clk);

        if (counting_cycles != 15000)
            $display("Hint: The second test case should count for 15000 cycles. Your circuit counted %0d", counting_cycles);
        counting_cycles <= 0;

        if (failed)
            $display("Hint: Your FSM didn't pass the sample timing diagram posted with the problem statement. Perhaps try debugging that?");
        
    
        repeat(1000) @(posedge clk, negedge clk) begin
            reset <= !($random & 8191);
            data <= $random;
            ack <= !($random & 31);
        end
        repeat(100000) @(posedge clk) begin
            reset <= !($random & 8191);
            data <= $random;
            ack <= !($random & 31);
        end

        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_count;
        int errortime_count;
        int errors_counting;
        int errortime_counting;
        int errors_done;
        int errortime_done;

        int clocks;
    } stats;
    
    stats stats1;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic reset;
    logic data;
    logic ack;
    logic [3:0] count_ref;
    logic [3:0] count_dut;
    logic counting_ref;
    logic counting_dut;
    logic done_ref;
    logic done_dut;

    // Queues for mismatch reporting
    localparam MAX_QUEUE_SIZE = 10;
    logic [3:0] q_reset [$];
    logic [0:0] q_data [$];
    logic [0:0] q_ack [$];
    logic [3:0] q_count_dut [$];
    logic [0:0] q_counting_dut [$];
    logic [0:0] q_done_dut [$];
    logic [3:0] q_count_ref [$];
    logic [0:0] q_counting_ref [$];
    logic [0:0] q_done_ref [$];

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,data,ack,count_ref,count_dut,counting_ref,counting_dut,done_ref,done_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .reset,
        .data,
        .ack );
    RefModule good1 (
        .clk,
        .reset,
        .data,
        .ack,
        .count(count_ref),
        .counting(counting_ref),
        .done(done_ref) );
        
    TopModule top_module1 (
        .clk,
        .reset,
        .data,
        .ack,
        .count(count_dut),
        .counting(counting_dut),
        .done(done_dut) );

    assign tb_match = ( { count_ref, counting_ref, done_ref } === ( { count_ref, counting_ref, done_ref } ^ { count_dut, counting_dut, done_dut } ^ { count_ref, counting_ref, done_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Queue management
        if (q_reset.size() >= MAX_QUEUE_SIZE) begin
            q_reset.delete(0);
            q_data.delete(0);
            q_ack.delete(0);
            q_count_dut.delete(0);
            q_counting_dut.delete(0);
            q_done_dut.delete(0);
            q_count_ref.delete(0);
            q_counting_ref.delete(0);
            q_done_ref.delete(0);
        end

        q_reset.push_back(reset);
        q_data.push_back(data);
        q_ack.push_back(ack);
        q_count_dut.push_back(count_dut);
        q_counting_dut.push_back(counting_dut);
        q_done_dut.push_back(done_dut);
        q_count_ref.push_back(count_ref);
        q_counting_ref.push_back(counting_ref);
        q_done_ref.push_back(done_ref);

        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Display first mismatch
            if (stats1.errors == 1) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %0d cycles of simulation:", q_reset.size());
                for (int i = 0; i < q_reset.size(); i++) begin
                    $display("Cycle %0d, reset=%b, data=%b, ack=%b | Got: count=%h(%b) counti=%b done=%b | Exp: count=%h(%b) counti=%b done=%b",
                        i,
                        q_reset[i],
                        q_data[i],
                        q_ack[i],
                        q_count_dut[i], q_count_dut[i], q_counting_dut[i], q_done_dut[i],
                        q_count_ref[i], q_count_ref[i], q_counting_ref[i], q_done_ref[i]
                    );
                end
            end
        end

        if (count_ref !== ( count_ref ^ count_dut ^ count_ref ))
        begin if (stats1.errors_count == 0) stats1.errortime_count = $time;
            stats1.errors_count = stats1.errors_count+1'b1; end
        if (counting_ref !== ( counting_ref ^ counting_dut ^ counting_ref ))
        begin if (stats1.errors_counting == 0) stats1.errortime_counting = $time;
            stats1.errors_counting = stats1.errors_counting+1'b1; end
        if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
        begin if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done = stats1.errors_done+1'b1; end
    end

    final begin
        if (stats1.errors == 0) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);

        if (stats1.errors_count) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "count", stats1.errors_count, stats1.errortime_count);
        else $display("Hint: Output '%s' has no mismatches.", "count");
        if (stats1.errors_counting) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "counting", stats1.errors_counting, stats1.errortime_counting);
        else $display("Hint: Output '%s' has no mismatches.", "counting");
        if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else $display("Hint: Output '%s' has no mismatches.", "done");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule