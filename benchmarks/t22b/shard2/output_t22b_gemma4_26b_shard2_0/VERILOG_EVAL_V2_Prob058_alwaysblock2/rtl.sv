module TopModule (
    input  logic clk,
    input  logic a,
    input  logic b,
    output logic out_assign,
    output logic out_always_comb,
    output logic out_always_ff
);

    // 1. Continuous assignment for XOR
    assign out_assign = a ^ b;

    // 2. Combinational always block for XOR
    always @(*) begin
        out_always_comb = a ^ b;
    end

    // 3. Clocked always block for registered XOR
    // We use an internal logic signal to act as the flip-flop
    always @(posedge clk) begin
        out_always_ff <= a ^ b;
    end

endmodule