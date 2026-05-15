module TopModule (
    input  logic [2:0] a,
    input  logic [2:0] b,
    output logic [2:0] out_or_bitwise,
    output logic       out_or_logical,
    output logic [5:0] out_not
);

    // Bitwise OR of the two 3-bit vectors
    assign out_or_bitwise = a | b;

    // Logical OR of the two vectors
    // In SystemVerilog, applying logical operators to vectors evaluates them as booleans
    assign out_or_logical = a || b;

    // Inverse of both vectors
    // Inverse of b in [5:3], inverse of a in [2:0]
    assign out_not = {~b, ~a};

endmodule