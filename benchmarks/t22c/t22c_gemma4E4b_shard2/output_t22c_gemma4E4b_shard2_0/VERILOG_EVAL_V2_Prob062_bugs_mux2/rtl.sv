module TopModule (
    input  logic sel,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic out
);

    // Standard 2-to-1 Multiplexer implementation
    // If sel=0, out = a
    // If sel=1, out = b
    assign out = (~sel & a) | (sel & b);

endmodule
