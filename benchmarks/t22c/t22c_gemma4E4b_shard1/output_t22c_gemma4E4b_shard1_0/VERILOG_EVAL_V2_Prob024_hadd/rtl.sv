module TopModule (
    input  logic a,
    input  logic b,
    output logic sum,
    output logic cout
);

    // Half Adder implementation:
    // Sum = A XOR B
    assign sum = a ^ b;

    // Carry Out = A AND B
    assign cout = a & b;

endmodule