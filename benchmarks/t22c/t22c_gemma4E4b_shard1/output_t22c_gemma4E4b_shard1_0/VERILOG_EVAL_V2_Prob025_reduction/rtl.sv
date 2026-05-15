module TopModule (
    input logic [7:0] in,
    output logic parity
);

    // Even parity is calculated by XORing all bits of the input vector.
    // The reduction operator '^' performs this operation efficiently.
    assign parity = ^in;

endmodule