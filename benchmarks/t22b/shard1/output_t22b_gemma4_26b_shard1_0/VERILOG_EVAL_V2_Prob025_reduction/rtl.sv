module TopModule (
    input  logic [7:0] in,
    output logic       parity
);

    // Even parity is the XOR sum of all input bits.
    // The reduction XOR operator '^in' computes in[0] ^ in[1] ^ ... ^ in[7].
    assign parity = ^in;

endmodule