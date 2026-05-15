module TopModule (input clk, input x, output z);
    logic q0, q1, q2;
    // D flip-flops
    always @(posedge clk) begin
        q0 <= x ^ q0;
    end
    always @(posedge clk) begin
        q1 <= x & ~q1;
    end
    always @(posedge clk) begin
        q2 <= x | ~q2;
    end
    // Three-input NOR gate for z
    assign z = ~(q0 | q1 | q2);
    // Initialize registers to zero
    initial begin
        q0 = 0;
        q1 = 0;
        q2 = 0;
    end
endmodule