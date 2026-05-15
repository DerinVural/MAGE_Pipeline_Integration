`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Reference Module
module RefModule (
    input  logic clk,
    input  logic aresetn,
    input  logic x,
    output logic z
);
    typedef enum logic [1:0] {S0, S1, S2} state_t;
    state_t state, next_state;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) state <= S0;
        else          state <= next_state;
    end

    always @(*) begin
        next_state = state;
        z = 1'b0;
        case (state) 
            S0: begin
                if (x) next_state = S1;
                else   next_state = S0;
            end
            S1: begin
                if (x) next_state = S1;
                else   next_state = S2;
            end
            S2: begin
                if (x) begin
                    z = 1'b1;
                    next_state = S1;
                end else begin
                    next_state = S0;
                end
            end
            default: next_state = S0;
        endcase
    end
endmodule

module stimulus_gen (
    input  logic clk,
    output logic aresetn,
    output logic x,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input  logic tb_match
);
    reg reset;
    assign aresetn = ~reset;

    task wavedrom_start(input [511:0] title = "");
        wavedrom_enable = 1;
        wavedrom_title = title;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable = 0;
    endtask    

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

    initial begin
        x <= 0;
        repeat(3) @(posedge clk);
        @(posedge clk) x <= 1;
        @(posedge clk) x <= 0;
        @(posedge clk) x <= 1;
    end
    
    initial begin
        reset <= 1;
        @(posedge clk) reset <= 0;
        reset_test(1);
        
        @(negedge clk) wavedrom_start();
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 1;
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 1;
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 1;
            @(posedge clk) x <= 1;
            @(posedge clk) x <= 0;
            @(posedge clk) x <= 1;
            @(posedge clk) x <= 0;
        @(negedge clk) wavedrom_stop();

        repeat(400) @(posedge clk, negedge clk) begin
            x <= $random;
            reset <= ($random&31) == 0;
        end
        
        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic aresetn;
    logic x;
    logic z_ref;
    logic z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, aresetn, x, z_ref, z_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .aresetn,
        .x,
        .wavedrom_title,
        .wavedrom_enable,
        .tb_match
    );

    RefModule good1 (
        .clk,
        .aresetn,
        .x,
        .z(z_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .aresetn,
        .x,
        .z(z_dut)
    );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            if (stats1.errors == 1) begin
                $display("FIRST MISMATCH DETECTED AT TIME %0t:", $time);
                $display("Inputs: x=%b, aresetn=%b", x, aresetn);
                $display("Outputs: z_dut=%b, z_ref=%b", z_dut, z_ref);
                $display("Expected: z=%b", z_ref);
            end
        end
        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1'b1;
        end
    end

    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    initial begin
      #1000000;
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0 && stats1.errors_z == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
        end

        if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output '%s' has no mismatches.", "z");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
endmodule