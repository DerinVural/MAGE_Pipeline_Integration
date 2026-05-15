`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output areset,
    output reg load,
    output reg ena,
    output reg[3:0] data,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;

    task reset_test(input async=0);
        bit arfail, srfail, datafail;
    
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
    
        @(negedge clk) begin datafail = !tb_match ; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        {load, ena, reset, data} <= 7'h40;
        @(posedge clk) {load, ena, reset, data} <= 7'h4f;
        wavedrom_start("Load and reset");
        @(posedge clk) {load, ena, reset, data} <= 7'h0x;
        @(posedge clk) {load, ena, reset, data} <= 7'h2x;
        @(posedge clk) {load, ena, reset, data} <= 7'h2x;
        @(posedge clk) {load, ena, reset, data} <= 7'h0x;
        reset_test(1);
        @(posedge clk);
        @(posedge clk);
        wavedrom_stop();
        
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
            load <= !($random & 15);
            ena <= |($random & 31);
            data <= $random;
        end
        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic areset;
    logic load;
    logic ena;
    logic [3:0] data;
    logic [3:0] q_ref;
    logic [3:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,load,ena,data,q_ref,q_dut );
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .areset,
        .load,
        .ena,
        .data );

    // Note: RefModule is assumed to be provided by the environment per the error logs
    RefModule good1 (
        .clk,
        .areset,
        .load,
        .ena,
        .data,
        .q(q_ref) );
        
    TopModule top_module1 (
        .clk,
        .areset,
        .load,
        .ena,
        .data,
        .q(q_dut) );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
            $display("Hint: Output 'q' has no mismatches.");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("First mismatch at time %0t:", $time);
                $display("Inputs: clk=%b, areset=%b, load=%b, ena=%b, data=%h (%b)", clk, areset, load, ena, data, data);
                $display("Outputs: q_ref=%h (%b), q_dut=%h (%b)", q_ref, q_ref, q_dut, q_dut);
            end
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) begin
                stats1.errortime_q = $time;
            end
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end
endmodule