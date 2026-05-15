module TopModule (
    input  logic [99:0] in,
    output logic out_and,
    output logic out_or,
    output logic out_xor
);

    // (1) out_and: 100-input AND gate
    // out_and is high (1) only if all bits in 'in' are high (1).
    assign out_and = &in;

    // (2) out_or: 100-input OR gate
    // out_or is high (1) if at least one bit in 'in' is high (1).
    assign out_or = |in;

    // (3) out_xor: 100-input XOR gate
    // out_xor is high (1) if the count of '1's in 'in' is odd.
    assign out_xor = ^in;

endmodule