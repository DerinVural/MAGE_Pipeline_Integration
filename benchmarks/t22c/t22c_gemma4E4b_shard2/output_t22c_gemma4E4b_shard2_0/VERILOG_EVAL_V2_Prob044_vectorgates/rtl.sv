module TopModule(
    input logic [2:0] a,
    input logic [2:0] b,
    output logic [2:0] out_or_bitwise,
    output logic out_or_logical,
    output logic [5:0] out_not
);

    // 1. Bitwise OR of a and b
    assign out_or_bitwise = a | b;

    // 2. Logical OR of a and b (1 if any bit in a or b is 1)
    // Since a and b are 3 bits, the logical OR is true if the bitwise OR result is non-zero.
    assign out_or_logical = (a | b) != 3'b0;

    // 3. Inverse (NOT) of a and b, arranged as {~b, ~a}
    // ~b goes into the upper half [5:3]
    // ~a goes into the lower half [2:0]
    assign out_not = {~b, ~a};

endmodule