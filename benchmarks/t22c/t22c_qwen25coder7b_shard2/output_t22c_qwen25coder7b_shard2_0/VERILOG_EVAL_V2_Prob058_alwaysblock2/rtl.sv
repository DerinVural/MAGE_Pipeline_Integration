module TopModule(
    input logic clk,
    input logic a,
    input logic b,
    output logic out_assign,
    output logic out_always_comb,
    output logic out_always_ff
);

    // Using assign statement for XOR operation
    assign out_assign = a ^ b;

    // Using combinational always block for XOR operation
    logic xor_comb;
    always @(*) begin
        xor_comb = a ^ b;
    end
    assign out_always_comb = xor_comb;

    // Using clocked always block for XOR operation
    logic xor_ff;
    always @(posedge clk) begin
        xor_ff <= a ^ b;
    end
    assign out_always_ff = xor_ff;

endmodule;