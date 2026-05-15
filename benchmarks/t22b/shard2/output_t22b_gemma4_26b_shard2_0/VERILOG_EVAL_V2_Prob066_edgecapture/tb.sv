module RefModule (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] in,
    output logic [31:0] out
);
    logic [31:0] in_reg;
    logic [31:0] out_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            out_reg <= 32'h0;
        end else begin
            in_reg <= in;
            out_reg <= out_reg | (~in & in_reg);
        end
    end
    assign out = out_reg;
endmodule

module stimulus_gen (
    input clk,
    input tb_match,
    output logic [31:0] in,
    output logic reset,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable    
);

    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable = 0;
    endtask    

    initial begin
        in <= 0;
        reset <= 1;
        @(posedge clk);
        reset <= 1;
        in = 0;
        @(negedge clk) wavedrom_start("Example");
        repeat(1) @(posedge clk);
        reset = 0;
        @(posedge clk) in = 32'h2;
        repeat(4) @(posedge clk);
        in = 32'he;
        repeat(2) @(posedge clk);
        in = 0;
        @(posedge clk) in = 32'h2;
        repeat(2) @(posedge clk);
        reset = 1;
        @(posedge clk);
        reset = 0; in = 0;
        repeat(3) @(posedge clk);

        @(negedge clk) wavedrom_stop();

        @(negedge clk) wavedrom_start("");
        repeat(2) @(posedge clk);
        in <= 1;
        repeat(2) @(posedge clk);
        in <= 0;
        repeat(2) @(negedge clk);
        in <= 6;
        repeat(1) @(negedge clk);
        in <= 0;        
        repeat(2) @(posedge clk);
        in <= 32'h10;        
        repeat(2) @(posedge clk);
        reset <= 1;
        repeat(1) @(posedge clk);
        in <= 32'h0;
        repeat(1) @(posedge clk);
        reset <= 0;
        repeat(1) @(posedge clk);
        reset <= 1;
        in <= 32'h20;
        repeat(1) @(posedge clk);
        reset <= 0;
        in <= 32'h00;
    
        repeat(2) @(posedge clk);

        @(negedge clk) wavedrom_stop();
    
        repeat(200)
            @(posedge clk, negedge clk) begin
                in <= $random;
                reset <= !($random & 15);
            end
        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic [31:0] in;
    logic [31:0] out_ref;
    logic [31:0] out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, in, out_ref, out_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .tb_match,
        .in,
        .reset,
        .wavedrom_title,
        .wavedrom_enable 
    );

    RefModule good1 (
        .clk,
        .reset,
        .in,
        .out(out_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .reset,
        .in,
        .out(out_dut) 
    );

    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            if (stats1.errors == 1) begin
                $display("FIRST MISMATCH DETECTED AT TIME %0t:", $time);
                $display("in:      %h (%b)", in, in);
                $display("out_dut: %h (%b)", out_dut, out_dut);
                $display("out_ref: %h (%b)", out_ref, out_ref);
            end
        end

        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1'b1; 
        end
    end

    initial begin
      #1000000;
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors_out) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
        else 
            $display("Hint: Output '%s' has no mismatches.", "out");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);

        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
    end

endmodule