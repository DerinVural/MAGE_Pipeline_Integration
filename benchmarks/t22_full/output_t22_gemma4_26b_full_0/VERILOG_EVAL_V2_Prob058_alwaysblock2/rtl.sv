module TopModule(
    input  logic clk,
    input  logic a,
    input  logic b,
    output logic out_assign,
    output logic out_always_comb,
    output logic out_always_ff
);

    // 1. XOR using assign statement
    assign out_assign = a ^ b;

    // 2. XOR using combinational always block
    always @(*) begin
        out_always_comb = a ^ b;
    end

    // 3. XOR using clocked always block (Sequential logic)
    // This implementation introduces a one-cycle delay due to the flip-flop.
    always @(posedge clk) begin
        out_always_ff <= a ^ b;
    end

endmodule