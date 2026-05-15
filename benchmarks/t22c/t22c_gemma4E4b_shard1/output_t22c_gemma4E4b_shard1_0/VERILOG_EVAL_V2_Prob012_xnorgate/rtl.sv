module TopModule (
    input  logic a,
    input  logic b,
    output logic out
);

    // XNOR operation: out = a XNOR b
    // Equivalent to: out = ~(a ^ b)
    assign out = a ^ b ^ 1'b1;

endmodule