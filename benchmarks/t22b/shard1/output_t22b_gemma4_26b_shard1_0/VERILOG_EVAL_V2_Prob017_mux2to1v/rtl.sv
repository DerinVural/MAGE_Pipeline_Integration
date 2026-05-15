module TopModule (
    input  logic [99:0] a,
    input  logic [99:0] b,
    input  logic        sel,
    output logic [99:0] out
);

    // Combinational multiplexer logic
    // If sel is 1, out = b. If sel is 0, out = a.
    assign out = sel ? b : a;

endmodule