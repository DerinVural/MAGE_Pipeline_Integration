module TopModule (
    input logic clk,
    input logic a,
    input logic b,
    output logic out_assign,
    output logic out_always_comb,
    output logic out_always_ff
);

    // Assign statement implementation
    assign out_assign = a ^ b;

    // Combinational always block implementation
    always @(*) begin
        out_always_comb = a ^ b;
    end

    // Clocked always block implementation (flip-flop)
    always @(posedge clk) begin
        out_always_ff <= a ^ b;
    end

endmodule