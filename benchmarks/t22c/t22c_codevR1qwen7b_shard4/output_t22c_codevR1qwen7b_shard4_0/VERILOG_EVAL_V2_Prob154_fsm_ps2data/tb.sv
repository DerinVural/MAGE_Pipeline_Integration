`timescale 1ps/1ps
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
    
    stats stats1 = '0;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk = 0;
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
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_bytes_ref,out_bytes_dut,done_ref,done_dut );
    end
    
    wire tb_match;       // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .reset(reset)
    );
    RefModule good1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .out_bytes(out_bytes_ref),
        .done(done_ref)
    );
    
    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .out_bytes(out_bytes_dut),
        .done(done_dut)
    );
    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask    
    
    final begin
        if (stats1.errors_out_bytes) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_bytes, stats1.errortime_out_bytes);
        else if (stats1.errors_done) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_done, stats1.errortime_done);
        else $display("SIMULATION PASSED");
        
        if (stats1.errors_out_bytes) $display("First mismatch at out_bytes: ref=%h dut=%h", out_bytes_ref, out_bytes_dut);
        if (stats1.errors_done) $display("First mismatch at done: ref=%h dut=%h", done_ref, done_dut);
        
        $display("out_bytes_ref: %h", out_bytes_ref);
        $display("out_bytes_dut: %b", out_bytes_dut);
        $display("done_ref: %b", done_ref);
        $display("done_dut: %b", done_dut);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_bytes_ref, done_ref } === ( { out_bytes_ref, done_ref } ^ { out_bytes_dut, done_dut } ^ { out_bytes_ref, done_ref } ) );
    // Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
    // the sensitivity list of the @(strobe) process, which isn't implemented.
    always @(posedge clk, negedge clk) begin
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_bytes_ref !== ( out_bytes_ref ^ out_bytes_dut ^ out_bytes_ref )) begin
            if (stats1.errors_out_bytes == 0) stats1.errortime_out_bytes = $time;
            stats1.errors_out_bytes += 1;
        end
        if (done_ref !== ( done_ref ^ done_dut ^ done_ref )) begin
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done += 1;
        end
    end
    
    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end
endmodule