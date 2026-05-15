module TopModule(
    input  logic [7:0] in,
    output logic       parity
);

    // Even parity is the XOR sum of all bits.
    // If the number of 1s is odd, parity is 1 (making total 1s even).
    // If the number of 1s is even, parity is 0 (making total 1s even).
    assign parity = ^in;

endmodule