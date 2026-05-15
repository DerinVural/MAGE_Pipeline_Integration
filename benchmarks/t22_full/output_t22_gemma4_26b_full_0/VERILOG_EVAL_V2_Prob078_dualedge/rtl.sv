module TopModule(
    input  logic clk,
    input  logic d,
    output logic q
);

    // Internal registers to capture d on both edges
    logic q_pos;
    logic q_neg;

    // Initialize registers to avoid 'X' state
    initial begin
        q_pos = 1'b0;
        q_neg = 1'b0;
    end

    // Capture input on the rising edge
    always @(posedge clk) begin
        q_pos <= d;
    end

    // Capture input on the falling edge
    always @(negedge clk) begin
        q_neg <= d;
    end

    // The output q is the most recently captured value.
    // When clk is high, the last edge was the posedge.
    // When clk is low, the last edge was the negedge.
    // However, to behave like a true dual-edge FF where q follows d on every edge,
    // we can use the property that q should be q_pos when clk is high 
    // and q_neg when clk is low? No, that's not quite right.
    // Actually, the simplest functional way to implement a dual-edge FF in RTL 
    // is to use the two registers and a mux controlled by the clock.
    
    always @(*) begin
        if (clk) begin
            q = q_pos;
        end else begin
            q = q_neg;
        end
    end

    // Note: In some edge cases of the clock transition, there might be a tiny glitch.
    // But for functional behavior in a synchronous/dual-edge context, 
    // this logic correctly picks the value from the most recent edge.
    // For a more robust version, we use the logic that on posedge, q becomes d.
    // On negedge, q becomes d.
    // This implementation: 
    // At posedge: q_pos updated to d. clk becomes 1. q = q_pos (which is d).
    // At negedge: q_neg updated to d. clk becomes 0. q = q_neg (which is d).

endmodule