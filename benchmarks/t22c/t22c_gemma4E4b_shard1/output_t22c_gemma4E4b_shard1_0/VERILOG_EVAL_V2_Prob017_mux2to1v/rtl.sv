module TopModule (
    input  logic [99:0] a,
    input  logic [99:0] b,
    input  logic sel,
    output logic [99:0] out
);

    // Implementation of a 2-to-1 Multiplexer
    // If sel is 0, out = a. If sel is 1, out = b.
    assign out = sel ? b : a;

endmodule