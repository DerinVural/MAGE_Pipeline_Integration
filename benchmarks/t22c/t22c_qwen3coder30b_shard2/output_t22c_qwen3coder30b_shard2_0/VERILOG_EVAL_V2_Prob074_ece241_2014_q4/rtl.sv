module TopModule (
    input clk,
    input x,
    output z
);

    // Internal signals
    logic xor_out;
    logic and_out;
    logic or_out;
    
    // Flip-flop outputs
    logic q_xor;
    logic q_and;
    logic q_or;
    
    // Sequential logic for flip-flops
    always @(posedge clk) begin
        q_xor <= xor_out;
        q_and <= and_out;
        q_or <= or_out;
    end
    
    // Initialize flip-flops to 0
    initial begin
        q_xor = 0;
        q_and = 0;
        q_or = 0;
    end
    
    // Combinational logic for gates
    always @(*) begin
        xor_out = x ^ q_xor;
        and_out = x & ~q_and;
        or_out = x | ~q_or;
    end
    
    // Final NOR gate
    assign z = ~(xor_out | and_out | or_out);
    
endmodule