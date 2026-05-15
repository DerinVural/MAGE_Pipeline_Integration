module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // The truth table analysis shows that q is the negation of the XOR sum of the inputs.
    // q = ~(a ^ b ^ c ^ d)
    assign q = ~(a ^ b ^ c ^ d);

endmodule