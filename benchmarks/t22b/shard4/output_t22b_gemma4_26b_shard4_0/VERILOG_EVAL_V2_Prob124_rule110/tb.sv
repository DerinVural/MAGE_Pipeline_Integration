`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input logic clk,
    output logic load,
    output logic [511:0] data,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1'b1;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable = 1'b0;
    endtask    

    initial begin
        data <= 0;
        data[0] <= 1'b1;
        load <= 1;
        @(posedge clk); wavedrom_start("Load q[511:0] = 1: See Hint.");
        @(posedge clk);
        @(posedge clk);
        load <= 0;
        repeat(10) @(posedge clk);        
        wavedrom_stop();
        
        data <= 0;
        data[256] <= 1'b1;
        load <= 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk);
        data <= 512'h4df;
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk);
        data <= $random;
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk);

        data <= 0;
        load <= 1;
        repeat (20) @(posedge clk);
        @(posedge clk) data <= 2;
        @(posedge clk) data <= 4;
        @(posedge clk) begin
            data <= 9;
            load <= 0;
        end
        @(posedge clk) data <= 12;
        repeat(100) @(posedge clk);

        #1 $finish;
    end
endmodule

module RefModule (
    input logic clk,
    input logic load,
    input logic [511:0] data,
    output logic [511:0] q
);
    logic [511:0] q_reg;
    logic [511:0] next_q;

    always_comb begin
        for (int i = 0; i < 512; i++) begin
            logic L, C, R;
            C = q_reg[i];
            L = (i == 511) ? 1'b0 : q_reg[i+1];
            R = (i == 0)   ? 1'b0 : q_reg[i-1];
            case ({L, C, R})
                3'b111: next_q[i] = 1'b0;
                3'b110: next_q[i] = 1'b1;
                3'b101: next_q[i] = 1'b1;
                3'b100: next_q[i] = 1'b0;
                3'b011: next_q[i] = 1'b1;
                3'b010: next_q[i] = 1'b1;
                3'b001: next_q[i] = 1'b1;
                3'b000: next_q[i] = 1'b0;
                default: next_q[i] = 1'b0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (load) q_reg <= data;
        else      q_reg <= next_q;
    end
    assign q = q_reg;
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
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic load;
    logic [511:0] data;
    logic [511:0] q_ref;
    logic [511:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, load, data, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .load,
        .data,
        .wavedrom_title,
        .wavedrom_enable
    );

    RefModule good1 (
        .clk,
        .load,
        .data,
        .q(q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .load,
        .data,
        .q(q_dut)
    );

    assign tb_match = (q_ref === q_dut);

    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== q_dut) begin
            if (stats1.errors_q == 0) begin
                stats1.errortime_q = $time;
                $display("Mismatch detected at time %0t:", $time);
                $display("Input: load=%b, data=%h", load, data);
                if ($bits(data) <= 64) $display("Input data (BIN): %b", data);
                $display("Expected q: %h", q_ref);
                if ($bits(q_ref) <= 64) $display("Expected q (BIN): %b", q_ref);
                $display("Actual q:   %h", q_dut);
                if ($bits(q_dut) <= 64) $display("Actual q (BIN): %b", q_dut);
            end
            stats1.errors_q = stats1.errors_q + 1;
        end
    end

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

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule