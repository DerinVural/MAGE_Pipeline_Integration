module TopModule(
    input  logic clk,
    input  logic x,
    output logic z
);

    // D flip-flop outputs
    logic q_xor;
    logic q_and;
    logic q_or;

    // Initialization to zero as per specification
    initial begin
        q_xor = 1'b0;
        q_and = 1'b0;
        q_or  = 1'b0;
    end

    // Sequential logic for D flip-flops
    always @(posedge clk) begin
        q_xor <= x ^ q_xor;
        q_and <= x & (~q_and);
        q_or  <= x | (~q_or);
    end

    // Combinational logic for the output Z (3-input NOR gate)
    // Z = ~(q_xor | q_and | q_or)
    always @(*)
    begin
        z = ~(q_xor | q_and | q_or);
    end

endmodule