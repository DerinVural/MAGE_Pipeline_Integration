`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Implementation of the TopModule as per spec
module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    logic [2:0] state;
    logic [2:0] next_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= 3'b000;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            3'b000: next_state = x ? 3'b001 : 3'b000;
            3'b001: next_state = x ? 3'b100 : 3'b001;
            3'b010: next_state = x ? 3'b001 : 3'b010;
            3'b011: next_state = x ? 3'b010 : 3'b001;
            3'b100: next_state = x ? 3'b100 : 3'b011;
            default: next_state = 3'b000;
        endcase
    end

    always_comb begin
        case (state)
            3'b011: z = 1'b1;
            3'b100: z = 1'b1;
            default: z = 1'b0;
        endcase
    end

endmodule

module RefModule (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);
    // Behavioral model matching spec for reference
    logic [2:0] state;
    logic [2:0] next_state;

    always_ff @(posedge clk) begin
        if (reset) state <= 3'b000;
        else       state <= next_state;
    end

    always_comb begin
        case (state)
            3'b000: next_state = x ? 3'b001 : 3'b000;
            3'b001: next_state = x ? 3'b100 : 3'b001;
            3'b010: next_state = x ? 3'b001 : 3'b010;
            3'b011: next_state = x ? 3'b010 : 3'b001;
            3'b100: next_state = x ? 3'b100 : 3'b011;
            default: next_state = 3'b000;
        endcase
    end
    assign z = (state == 3'b011 || state == 3'b100);
endmodule

module stimulus_gen (
    input clk,
    output logic reset,
    output logic x
);

    initial begin
        reset = 1;
        x = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        @(posedge clk);
        
        repeat(500) @(negedge clk) begin
            reset <= !($random & 63);
            x <= $random;
        end
        
        #1 $finish;
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
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic reset;
    logic x;
    logic z_ref;
    logic z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,x,z_ref,z_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .reset,
        .x );
    
    RefModule good1 (
        .clk,
        .reset,
        .x,
        .z(z_ref) );
        
    TopModule top_module1 (
        .clk,
        .reset,
        .x,
        .z(z_dut) );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("FIRST MISMATCH DETECTED at time %0t", $time);
                $display("Inputs: clk=%b, reset=%b, x=%b", clk, reset, x);
                $display("Outputs: z_dut=%b, z_ref=%b", z_dut, z_ref);
            end
            stats1.errors++;
        end
        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z+1'b1; 
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output '%s' has no mismatches.", "z");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule