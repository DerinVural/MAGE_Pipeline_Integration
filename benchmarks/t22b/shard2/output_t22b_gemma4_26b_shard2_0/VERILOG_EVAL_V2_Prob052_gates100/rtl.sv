module TopModule (
    input  logic [99:0] in,
    output logic        out_and,
    output logic        out_or,
    output logic        out_xor
);

    // Reduction operators are used to implement n-input gates
    assign out_and = &in; // Performs in[99] & in[98] & ... & in[0]
    assign out_or  = |in; // Performs in[99] | in[98] | ... | in[0]
    assign out_xor = ^in; // Performs in[99] ^ in[98] ^ ... ^ in[0]

endmodule