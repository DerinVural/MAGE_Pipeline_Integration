module TopModule(
    input  logic a,
    input  logic b,
    input  logic sel,
    output logic out
);

    // Combinational logic for 2-to-1 multiplexer
    // When sel is 0, out = a. When sel is 1, out = b.
    assign out = sel ? b : a;

endmodule