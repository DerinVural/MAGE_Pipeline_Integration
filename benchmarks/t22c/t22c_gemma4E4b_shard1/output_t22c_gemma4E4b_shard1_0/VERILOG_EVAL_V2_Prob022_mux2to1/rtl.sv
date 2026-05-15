module TopModule (
    input  logic a,
    input  logic b,
    input  logic sel,
    output logic out
);

    // Implement 2-to-1 MUX logic using a continuous assignment
    // When sel=0, out = a. When sel=1, out = b.
    assign out = sel ? b : a;

endmodule